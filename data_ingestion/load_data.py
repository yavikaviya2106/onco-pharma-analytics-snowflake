from pathlib import Path

from utils.config import FILE_FORMAT, SNOWFLAKE_CONFIG, STAGE
from utils.logger import get_logger
from utils.snowflake_connection import get_snowflake_data_ing_env_connection

logger = get_logger(__name__)
DATABASE = SNOWFLAKE_CONFIG["database"].upper()


def load_data(upload_result: dict) -> dict:
    
    if upload_result["status"] == "SKIPPED":
        logger.info("Already ingested: %s", upload_result["file_path"])
        return {"status": "SKIPPED", "table": upload_result["table"], "rows_loaded": 0}
    
    table = upload_result["table"]
    stage_path = upload_result["stage_path"]
    file_hash = upload_result["file_hash"]
    file_name = Path(upload_result["file_path"]).name
    audit = f"{DATABASE}.CONTROL.FILE_INGESTION_AUDIT"
    
    conn = get_snowflake_data_ing_env_connection()
    
    try:
        with conn.cursor() as cursor:
            cursor.execute(f"SELECT COUNT(*) FROM {audit} WHERE SOURCE_TABLE=%s AND FILE_HASH=%s", (table, file_hash))
            
            if cursor.fetchone()[0]:
                logger.info("Already audited: %s", file_name)
                return {"status": "SKIPPED", "table": table, "rows_loaded": 0}
            
            # Snowflake COPY tracks staged file load history; FORCE=FALSE avoids reloading the same staged object.
            cursor.execute(f"""
                COPY INTO {table}
                FROM @{STAGE}/{stage_path}/
                FILE_FORMAT = (FORMAT_NAME = '{FILE_FORMAT}')
                ON_ERROR = ABORT_STATEMENT
                FORCE = FALSE
            """)
            
            result = cursor.fetchall()
            if len(result) != 1:
                raise RuntimeError(f"Expected one staged file, got: {result}")
            
            row = result[0]
            status = str(row[1]).upper()
            rows_loaded = int(row[3] or 0)
            errors = int(row[5] or 0)
            
            if status not in ("LOADED", "PARTIALLY_LOADED") or errors:
                raise RuntimeError(f"COPY did not load successfully: {row}")
            
            cursor.execute(f"""
                INSERT INTO {audit} (SOURCE_TABLE, SOURCE_FILE, FILE_HASH, ROWS_LOADED)
                VALUES (%s, %s, %s, %s)
            """, (table, file_name, file_hash, rows_loaded))
        
        conn.commit()
        
        logger.info("Loaded %d rows into %s from %s", rows_loaded, table, file_name)
        return {"status": "LOADED", "table": table, "rows_loaded": rows_loaded}
    
    except Exception:
        conn.rollback()
        logger.exception("Snowflake load failed for %s", file_name)
        raise
    
    finally:
        conn.close()

from pathlib import Path
import sqlparse

from utils.config import SNOWFLAKE_CONFIG
from utils.logger import get_logger
from utils.snowflake_connection import get_snowflake_data_ing_env_connection

logger = get_logger(__name__)

DDL_FILE = Path(__file__).with_name("snowflake_source_tables_ddl.sql")


def create_tables():
    if not DDL_FILE.is_file():
        raise FileNotFoundError(DDL_FILE)
    logger.info("Initializing Snowflake source tables")

    conn = get_snowflake_data_ing_env_connection()

    try:
        with conn.cursor() as cursor:
            database = SNOWFLAKE_CONFIG["database"]

            sql = DDL_FILE.read_text(encoding="utf-8")

            for statement in sqlparse.split(sql):
                if statement.strip():
                    cursor.execute(statement)

            cursor.execute(f"CREATE SCHEMA IF NOT EXISTS {database}.CONTROL")

            cursor.execute(f"""
                CREATE TABLE IF NOT EXISTS
                {database}.CONTROL.FILE_INGESTION_AUDIT (
                    SOURCE_TABLE VARCHAR,
                    SOURCE_FILE VARCHAR,
                    FILE_HASH VARCHAR(64),
                    ROWS_LOADED NUMBER,
                    LOADED_AT TIMESTAMP_LTZ
                        DEFAULT CURRENT_TIMESTAMP()
                )
            """)

        conn.commit()
        logger.info("Snowflake source tables and ingestion audit initialized")

    finally:
        conn.close()

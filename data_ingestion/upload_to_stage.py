import hashlib
from pathlib import Path

from utils.config import SOURCE_DIR, STAGE, SNOWFLAKE_CONFIG
from utils.logger import get_logger
from utils.snowflake_connection import get_snowflake_data_ing_env_connection

logger = get_logger(__name__)


def calculate_file_hash(path: Path) -> str:
    sha256 = hashlib.sha256()

    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(64 * 1024), b""):
            sha256.update(chunk)

    return sha256.hexdigest()


def upload_to_stage(file_path: str) -> dict:
    source_dir = Path(SOURCE_DIR).resolve()
    path = Path(file_path).resolve()

    if not path.is_file() or not path.is_relative_to(source_dir):
        raise ValueError(f"Invalid source CSV path: {path}")

    if path.suffix.lower() != ".csv":
        raise ValueError(f"Expected CSV input: {path}")

    parts = path.relative_to(source_dir).parts

    if len(parts) != 3:
        raise ValueError(
            "Expected source layout: SOURCE_DIR/schema/table/file.csv"
        )

    schema, table_name = parts[0].upper(), parts[1].upper()
    database = SNOWFLAKE_CONFIG["database"].upper()

    stage_name = (
        f"{database}.{SNOWFLAKE_CONFIG['schema'].upper()}.{STAGE}"
    )

    table = f"{database}.{schema}.{table_name}"
    audit = f"{database}.CONTROL.FILE_INGESTION_AUDIT"

    file_hash = calculate_file_hash(path)

    stage_path = f"{schema}/{table_name}/{file_hash}"

    result_info = {
        "table": table,
        "file_path": str(path),
        "file_hash": file_hash,
        "stage_path": stage_path,
    }

    conn = get_snowflake_data_ing_env_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT COUNT(*)
                FROM {audit}
                WHERE SOURCE_TABLE = %s
                  AND FILE_HASH = %s
                """,
                (table, file_hash),
            )

            if cursor.fetchone()[0] > 0:
                logger.info(
                    "Skipping previously loaded file: %s",
                    path
                )
                return {"status": "SKIPPED", **result_info}

            cursor.execute(
                f"LIST @{stage_name}/{stage_path}/"
            )

            existing = cursor.fetchall()

            if existing:
                logger.info(
                    "Existing staged file found; reusing for retry: %s",
                    path.name,
                )

            else:
                uri = path.as_uri()

                if "'" in uri:
                    raise ValueError(
                        "Unsupported single quote in file URI"
                    )

                cursor.execute(
                    f"PUT '{uri}' @{stage_name}/{stage_path}/ "
                    "AUTO_COMPRESS=TRUE OVERWRITE=FALSE PARALLEL=1"
                    
                )

                result = cursor.fetchall()

                if (
                    len(result) != 1
                    or str(result[0][6]).upper()
                    not in ("UPLOADED", "SKIPPED")
                ):
                    raise RuntimeError(
                        f"Snowflake PUT failed: {result}"
                    )

                logger.info(
                    "Staged %s at @%s/%s/",
                    path.name,
                    stage_name,
                    stage_path,
                )

        return {"status": "READY", **result_info}

    finally:
        conn.close()

from airflow.sdk import Asset, AssetAlias

from utils.config import SNOWFLAKE_CONFIG, SCHEMAS


DATABASE = SNOWFLAKE_CONFIG["database"].strip().upper()

ALLOWED_SCHEMAS = {
    schema.strip().upper()
    for schema in SCHEMAS
    if schema.strip()
}


RAW_TABLE_ALIAS = AssetAlias("raw_table_loaded")


def get_raw_asset(table: str) -> Asset:

    if not isinstance(table, str) or not table.strip():
        raise ValueError("Snowflake table name cannot be empty.")

    parts = [
        part.strip().upper()
        for part in table.split(".")
    ]

    if len(parts) == 3:
        database, schema, table_name = parts

    elif len(parts) == 2:
        database = DATABASE
        schema, table_name = parts

    else:
        raise ValueError(
            "Expected SCHEMA.TABLE or DATABASE.SCHEMA.TABLE. "
            f"Received: {table}"
        )

    if not all(parts):
        raise ValueError(
            f"Invalid Snowflake table identifier: {table}"
        )

    if database != DATABASE:
        raise ValueError(
            f"Unexpected Snowflake database: {database}"
        )

    if schema not in ALLOWED_SCHEMAS:
        raise ValueError(
            f"Schema '{schema}' is not configured in SCHEMAS."
        )

    if not table_name:
        raise ValueError("Snowflake table name cannot be empty.")

    return Asset(
        uri=f"snowflake://{database}/{schema}/{table_name}"
    )


RAW_INGESTION_COMPLETE = Asset(
    uri=(
        f"snowflake://{DATABASE}/CONTROL/"
        "RAW_INGESTION_COMPLETE"
    )
)

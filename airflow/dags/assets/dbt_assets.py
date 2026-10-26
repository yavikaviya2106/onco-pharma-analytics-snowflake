from airflow.sdk import Asset

from utils.config import SNOWFLAKE_DEV_CONFIG,SNOWFLAKE_PRD_CONFIG


DEV_DATABASE = SNOWFLAKE_DEV_CONFIG["database"].strip().upper()

DBT_DEV_COMPLETE = Asset(
    uri=f"snowflake://{DEV_DATABASE}/DEV/DBT_DEV_COMPLETE"
)

PRD_DATABASE = SNOWFLAKE_PRD_CONFIG["database"].strip().upper()

DBT_PRD_COMPLETE = Asset(
    uri=f"snowflake://{PRD_DATABASE}/PRD/DBT_PRD_COMPLETE"
)

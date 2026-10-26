import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()


def required_env(name):
    value = os.getenv(name)

    if not value or not value.strip():
        raise ValueError(
            f"{name} environment variable is required.")

    return value.strip()


# Source configuration
SOURCE_DIR = Path(
    os.getenv("SOURCE_DATA_DIR", "/opt/airflow/source_data")
)

# Snowflake connection for data ingestion
SNOWFLAKE_CONFIG = {
    "account": required_env("SNOWFLAKE_ACCOUNT"),
    "user": required_env("SNOWFLAKE_USER"),
    "password": required_env("SNOWFLAKE_PASSWORD"),
    "role": required_env("SNOWFLAKE_ROLE"),
    "warehouse": required_env("SNOWFLAKE_WAREHOUSE"),
    "database": required_env("SNOWFLAKE_SOURCE_DATA_DATABSE"),
    "schema": required_env("SNOWFLAKE_SCHEMA"),
}

# Snowflake connection for development
SNOWFLAKE_DEV_CONFIG = {
    "account": required_env("SNOWFLAKE_ACCOUNT"),
    "user": required_env("SNOWFLAKE_USER"),
    "password": required_env("SNOWFLAKE_PASSWORD"),
    "role": required_env("SNOWFLAKE_ROLE"),
    "warehouse": required_env("SNOWFLAKE_WAREHOUSE"),
    "database": required_env("SNOWFLAKE_DEV_DATABASE"),
}

# Snowflake connection for production
SNOWFLAKE_PRD_CONFIG = {
    "account": required_env("SNOWFLAKE_ACCOUNT"),
    "user": required_env("SNOWFLAKE_USER"),
    "password": required_env("SNOWFLAKE_PASSWORD"),
    "role": required_env("SNOWFLAKE_ROLE"),
    "warehouse": required_env("SNOWFLAKE_WAREHOUSE"),
    "database": required_env("SNOWFLAKE_PRD_DATABASE"),

}


# Source schemas
SCHEMAS = [
    schema.strip().upper()
    for schema in required_env("SCHEMAS").split(",")
    if schema.strip()
]

if not SCHEMAS:
    raise ValueError(
        "SCHEMAS must contain at least one valid schema.")


# Snowflake ingestion objects
FILE_FORMAT = required_env("FILE_FORMAT")
STAGE = required_env("STAGE")


# dbt configuration
DBT_PROJECT_DIR = Path(
    os.getenv(
        "DBT_PROJECT_DIR",
        "/opt/airflow/data_transformation/onco_pharma_analytics_dbt"
    )
)

DBT_PROFILES_DIR = Path(
    os.getenv(
        "DBT_PROFILES_DIR",
        "/opt/airflow/data_transformation/onco_pharma_analytics_dbt"
    )
)

DBT_TARGET = os.getenv("DBT_TARGET", "dev").strip()


# Docker 
DBT_DOCKER_NETWORK = os.getenv(
    "DBT_DOCKER_NETWORK",
    "onco_pharma_analytics_onco_pharma_analytics_network"
)

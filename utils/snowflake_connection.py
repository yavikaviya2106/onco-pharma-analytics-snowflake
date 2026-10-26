import snowflake.connector

from utils.config import SNOWFLAKE_CONFIG,SNOWFLAKE_DEV_CONFIG
from utils.logger import get_logger

logger = get_logger(__name__)


def get_snowflake_data_ing_env_connection():
    try:
        conn = snowflake.connector.connect(**SNOWFLAKE_CONFIG)

        logger.info("Snowflake connection established successfully.")

        return conn

    except snowflake.connector.Error:
        logger.exception("Snowflake connection failed.")
        raise

def get_snowflake_dev_env_connection():
    try:
        conn = snowflake.connector.connect(**SNOWFLAKE_DEV_CONFIG)

        logger.info("Snowflake connection established successfully.")

        return conn

    except snowflake.connector.Error:
        logger.exception("Snowflake connection failed.")
        raise

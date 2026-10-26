from datetime import datetime, timedelta, timezone
from utils.config import SNOWFLAKE_DEV_CONFIG,DBT_DOCKER_NETWORK

from airflow.sdk import dag
from airflow.providers.docker.operators.docker import DockerOperator
from docker.types import Mount


from assets.source_data_asset import RAW_INGESTION_COMPLETE
from assets.dbt_assets import DBT_DEV_COMPLETE


@dag(
    dag_id="dbt_dev_transformation",
    schedule=[RAW_INGESTION_COMPLETE],
    start_date=datetime(2026, 10, 1, tzinfo=timezone.utc),
    catchup=False,
    max_active_runs=1,
    default_args={
        "retries": 0,
        "retry_delay": timedelta(minutes=5),
    },
    tags=["dbt", "dev", "transformation"],
)
def dbt_dev_transformation():
    DockerOperator(
        task_id="run_dbt_dev",
        image="onco-pharma-dbt:latest",
        mounts=[
            Mount(
                source="E:/Projects/onco-pharma-analytics-snowflake/data_transformation/onco_pharma_analytics_dbt",
                target="/app/dbt",
                type="bind",
            )
    ],
        entrypoint=["/bin/sh", "-c"],
        command=[
            "set -e &&"
            "dbt --version && "
            "dbt debug --target dev && "
            "dbt deps && "
            "dbt build --target dev"
        ],
        docker_url="unix://var/run/docker.sock",
        network_mode=DBT_DOCKER_NETWORK,
        environment={
            "DBT_PROJECT_DIR": "/app/dbt",
            "DBT_PROFILES_DIR": "/app/dbt",

            "SNOWFLAKE_ACCOUNT": SNOWFLAKE_DEV_CONFIG["account"],
            "SNOWFLAKE_USER": SNOWFLAKE_DEV_CONFIG["user"],
            "SNOWFLAKE_PASSWORD": SNOWFLAKE_DEV_CONFIG["password"],
            "SNOWFLAKE_ROLE": SNOWFLAKE_DEV_CONFIG["role"],
            "SNOWFLAKE_WAREHOUSE": SNOWFLAKE_DEV_CONFIG["warehouse"],
            "SNOWFLAKE_DEV_DATABASE": SNOWFLAKE_DEV_CONFIG["database"],
        },
        auto_remove="success",
        mount_tmp_dir=False,
        force_pull=False,
        do_xcom_push=False,
        outlets=[DBT_DEV_COMPLETE],
    )


dbt_dev_transformation()

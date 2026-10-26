
from datetime import datetime, timedelta, timezone

from airflow.sdk import dag, task

from assets.source_data_asset import (
    RAW_TABLE_ALIAS,
    get_raw_asset,
    RAW_INGESTION_COMPLETE,
)


@dag(
    dag_id="source_data_ingestion",
    schedule=None,
    start_date=datetime(2026, 10, 1, tzinfo=timezone.utc),
    catchup=False,
    max_active_runs=1,
    max_active_tasks=1,
    default_args={
        "retries": 0,
        "retry_delay": timedelta(minutes=5),
    },
    tags=["local", "snowflake", "source data", "ingestion"],
)
def source_data_ingestion():

    @task
    def initialize_tables():
        from data_ingestion.create_tables import create_tables
        create_tables()

    @task
    def discover_source_files():
        from data_ingestion.discover_files import discover_files
        return discover_files()

    @task(max_active_tis_per_dag=1)
    def upload_file(file_path: str):
        from data_ingestion.upload_to_stage import upload_to_stage
        return upload_to_stage(file_path)

    @task(
        max_active_tis_per_dag=1,
        outlets=[RAW_TABLE_ALIAS],)
    def load_file(upload_result: dict, **context):
        from data_ingestion.load_data import load_data

        result = load_data(upload_result)

        if result["status"] == "LOADED":
            asset = get_raw_asset(result["table"])

            context["outlet_events"][RAW_TABLE_ALIAS].add(
                asset,
                extra={
                    "table": result["table"],
                    "rows_loaded": result["rows_loaded"],
                    },
            )

        return result

    @task(outlets=[RAW_INGESTION_COMPLETE])
    def ingestion_complete(load_results: list[dict]):

        if not load_results:
            raise ValueError("No source files were processed.")

        loaded = sum(
            result["status"] == "LOADED"
            for result in load_results
        )

        skipped = sum(
            result["status"] == "SKIPPED"
            for result in load_results
        )

        if loaded + skipped != len(load_results):
            raise RuntimeError(
                "Some source files were not processed successfully."
            )

        # All-skipped is valid only when load_data verifies prior successful loads.
        # If SKIPPED can mean anything else, keep this gate strict.

        return {
            "status": "SUCCESS",
            "loaded_files": loaded,
            "skipped_files": skipped,
        }

    initialized = initialize_tables()

    files = discover_source_files()

    initialized >> files

    uploaded = upload_file.expand(
        file_path=files
    )

    loaded = load_file.expand(
        upload_result=uploaded
    )

    ingestion_complete(loaded)


source_data_ingestion()

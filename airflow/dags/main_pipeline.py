from datetime import datetime, timedelta, timezone

from airflow.sdk import dag
from airflow.providers.standard.operators.trigger_dagrun import (
    TriggerDagRunOperator,
)


@dag(
    dag_id="main_pipeline",
    schedule=None,
    start_date=datetime(
        2026, 10, 1, tzinfo=timezone.utc
    ),
    catchup=False,
    max_active_runs=1,
    default_args={
        "retries": 0,
        "retry_delay": timedelta(minutes=5),
    },
    tags=["main", "orchestration", "asset-driven"],
)
def main_pipeline():

    trigger_ingestion = TriggerDagRunOperator(
        task_id="trigger_source_data_ingestion",
        trigger_dag_id="source_data_ingestion",
        trigger_run_id="main_ingestion__{{ run_id }}",
        wait_for_completion=False,
        skip_when_already_exists=True,   # conflict -> task skipped, not failed
        reset_dag_run=False,
    )


main_pipeline()

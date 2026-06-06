"""
Pipeline de exemplo: Airbyte → Spark → dbt → ClickHouse
Gerenciado pelo Airflow.
"""
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

default_args = {
    "owner": "data-platform",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="example_pipeline",
    default_args=default_args,
    description="Airbyte extract → Spark transform → dbt model",
    schedule_interval="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["example", "medallion"],
) as dag:

    # 1. Trigger Airbyte sync via API
    trigger_airbyte = BashOperator(
        task_id="trigger_airbyte_sync",
        bash_command="""
        curl -s -X POST http://airbyte-server:8001/api/v1/connections/sync \
          -H 'Content-Type: application/json' \
          -d '{"connectionId": "{{ var.value.airbyte_connection_id }}"}' \
          | python3 -c "import sys, json; d=json.load(sys.stdin); print(d['job']['id'])"
        """,
    )

    # 2. Spark job (submete via spark-submit ou chama o notebook via papermill)
    spark_transform = BashOperator(
        task_id="spark_transform",
        bash_command="""
        docker exec dp-spark-master spark-submit \
          --master spark://spark-master:7077 \
          /opt/airflow/dags/jobs/transform_example.py \
          --date {{ ds }}
        """,
    )

    # 3. dbt bronze
    dbt_bronze = BashOperator(
        task_id="dbt_bronze",
        bash_command="cd /opt/airflow/dbt && dbt run --select tag:bronze --target prod",
    )

    # 4. dbt silver
    dbt_silver = BashOperator(
        task_id="dbt_silver",
        bash_command="cd /opt/airflow/dbt && dbt run --select tag:silver --target prod",
    )

    # 5. dbt gold
    dbt_gold = BashOperator(
        task_id="dbt_gold",
        bash_command="cd /opt/airflow/dbt && dbt run --select tag:gold --target prod",
    )

    # 6. dbt tests
    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command="cd /opt/airflow/dbt && dbt test --target prod",
    )

    # Pipeline order
    trigger_airbyte >> spark_transform >> dbt_bronze >> dbt_silver >> dbt_gold >> dbt_test

# ─────────────────────────────────────────────
# JupyterLab + PySpark 4.1.1
# Base: jupyter/base-notebook com Python 3.12
# ─────────────────────────────────────────────
FROM quay.io/jupyter/base-notebook:python-3.12

USER root

# Dependências de sistema para PySpark e conectores
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    curl \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Instala pacotes Python
RUN pip install --no-cache-dir \
    # Spark 4.0.1 + Delta Lake 4.x
    pyspark==4.0.1 \
    delta-spark==4.0.0 \
    # ClickHouse
    clickhouse-connect==0.8.14 \
    # S3 / MinIO
    boto3==1.35.0 \
    s3fs==2024.10.0 \
    pyarrow==17.0.0 \
    # Data wrangling
    pandas==2.2.3 \
    polars==1.6.0 \
    # dbt (para rodar no notebook)
    dbt-core==1.10.0 \
    dbt-clickhouse==1.10.0 \
    # Qualidade de dados
    great-expectations==1.3.0 \
    # JupyterLab extras
    jupyterlab==4.2.5 \
    ipywidgets==8.1.5

# Configuração Spark para S3/MinIO
COPY spark-defaults.conf /usr/local/spark/conf/spark-defaults.conf

USER jovyan

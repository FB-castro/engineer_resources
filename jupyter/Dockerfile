# ─────────────────────────────────────────────
# JupyterLab + PySpark 4.0.1
# Base: jupyter/base-notebook com Python 3.12
# ─────────────────────────────────────────────
FROM quay.io/jupyter/base-notebook:python-3.12

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    curl \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# 1. Spark + dados
RUN pip install --no-cache-dir \
    pyspark==4.0.1 \
    pandas==2.2.3 \
    pyarrow==17.0.0 \
    polars==1.6.0

# 2. S3 / MinIO
RUN pip install --no-cache-dir \
    boto3==1.35.0 \
    s3fs==2024.10.0

# 3. ClickHouse (driver direto, sem dbt)
RUN pip install --no-cache-dir \
    clickhouse-connect==0.7.19

# 4. JupyterLab extras
RUN pip install --no-cache-dir \
    jupyterlab==4.2.5 \
    ipywidgets==8.1.5

# Notas:
#   - dbt roda no Airflow (BashOperator) — não precisa estar no Jupyter
#   - great-expectations removido (incompatível com pandas>=2.2)
#   - delta-spark removido (sem release compatível com pyspark 4.x)

COPY spark-defaults.conf /usr/local/spark/conf/spark-defaults.conf

USER jovyan

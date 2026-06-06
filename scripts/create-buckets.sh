#!/bin/sh
set -e

MC=/usr/bin/mc
ALIAS=local

echo "⏳ Aguardando MinIO ficar pronto..."
until $MC alias set $ALIAS http://minio:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"; do
  sleep 2
done

# Buckets da plataforma
for BUCKET in \
  raw-landing \
  bronze \
  silver \
  gold \
  spark-checkpoints \
  airbyte-logs \
  dbt-artifacts; do

  if ! $MC ls "$ALIAS/$BUCKET" > /dev/null 2>&1; then
    $MC mb "$ALIAS/$BUCKET"
    echo "✅ Bucket criado: $BUCKET"
  else
    echo "ℹ️  Bucket já existe: $BUCKET"
  fi
done

# Política de leitura pública para dbt-artifacts (opcional)
$MC anonymous set download "$ALIAS/dbt-artifacts"

echo "🎉 Buckets inicializados com sucesso!"

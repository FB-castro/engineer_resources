#!/bin/bash
set -e

CLICKHOUSE_CLIENT="clickhouse-client --user ${CLICKHOUSE_USER} --password ${CLICKHOUSE_PASSWORD}"

echo "⏳ Inicializando databases no ClickHouse..."

$CLICKHOUSE_CLIENT --query "CREATE DATABASE IF NOT EXISTS bronze;"
$CLICKHOUSE_CLIENT --query "CREATE DATABASE IF NOT EXISTS silver;"
$CLICKHOUSE_CLIENT --query "CREATE DATABASE IF NOT EXISTS gold;"
$CLICKHOUSE_CLIENT --query "CREATE DATABASE IF NOT EXISTS airbyte_raw;"

echo "✅ Databases criados: bronze, silver, gold, airbyte_raw"

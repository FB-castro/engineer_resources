-- PostgreSQL não suporta "CREATE DATABASE IF NOT EXISTS"
-- Usa SELECT + \gexec para criar apenas se não existir

SELECT 'CREATE DATABASE metabase'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'metabase'
)\gexec

-- airflow já é criado pelo POSTGRES_DB no docker-compose.yml

-- Cria databases para cada serviço que compartilha o Postgres
CREATE DATABASE IF NOT EXISTS metabase;
CREATE DATABASE IF NOT EXISTS airflow;

-- Airbyte usa banco próprio (airbyte-db container), mas caso queira consolidar:
-- CREATE DATABASE IF NOT EXISTS airbyte;

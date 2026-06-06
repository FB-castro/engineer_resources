# Data Platform — Template VM

Stack de engenharia de dados pronta para deploy em VM, com arquitetura medallion (bronze/silver/gold).

## Arquitetura

```
Fontes → Airbyte → MinIO (raw-landing)
                       ↓
                   Spark (transform) → MinIO (bronze/silver/gold)
                       ↓
                   dbt → ClickHouse (bronze / silver / gold databases)
                       ↓
                   Metabase (visualização)

                   Airflow orquestra tudo
```

## Serviços e Portas

| Serviço              | Versão       | URL                        | Credenciais padrão           |
|---------------------|--------------|----------------------------|------------------------------|
| Airflow              | 3.2.1        | http://localhost:8082       | admin / (ver .env)           |
| JupyterLab + PySpark | 4.1.1        | http://localhost:8888       | token no .env                |
| Spark Master UI      | 4.1.1        | http://localhost:8080       | —                            |
| MinIO Console        | latest       | http://localhost:9001       | minioadmin / (ver .env)      |
| ClickHouse HTTP      | 26.3-lts     | http://localhost:8123       | admin / (ver .env)           |
| Metabase             | v0.61.0      | http://localhost:3000       | configurar no primeiro uso   |
| Airbyte (abctl)      | OSS latest   | http://localhost:8000       | ver: `make airbyte-credentials` |
| PostgreSQL           | 17           | localhost:5432              | ver .env                     |
| Redis                | 7.4          | localhost:6379              | —                            |

> **⚠️ Airbyte**: o docker-compose foi depreciado na v1.0 (ago/2024). O deploy agora usa `abctl` (Kubernetes local via k3d). Use `make up-airbyte`.

## Primeiros passos

### 1. Pré-requisitos

- Docker >= 24 e Docker Compose >= 2.20
- Mínimo 16 GB RAM, 4 vCPUs, 100 GB disco

### 2. Configurar variáveis de ambiente

```bash
cp .env.example .env
# Edite o .env com suas senhas e gere as chaves do Airflow:
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

### 3. Subir a stack

```bash
make init        # configura UID e .env
make up          # sobe stack principal
make up-airbyte  # instala Airbyte via abctl (requer Docker + 4 GB livres)
```

### 4. Primeiro acesso

```bash
make airflow-ui   # http://localhost:8082
make metabase-ui  # http://localhost:3000
make airbyte-ui   # http://localhost:8000
```

### 5. dbt

```bash
make dbt-deps     # instala packages
make dbt-run      # roda todos os modelos
make dbt-test     # valida os dados
make dbt-docs     # documentação em http://localhost:8085
```

## Estrutura de pastas

```
data-platform/
├── docker-compose.yml         # Stack principal
├── docker-compose.airbyte.yml # Airbyte (separado por tamanho)
├── .env.example
├── Makefile
├── airflow/
│   ├── dags/                  # DAGs do Airflow
│   ├── logs/
│   └── plugins/
├── clickhouse/
│   └── config/                # users.xml, config.xml
├── dbt/
│   ├── models/
│   │   ├── bronze/            # Raw → ClickHouse bronze
│   │   ├── silver/            # Cleaned → ClickHouse silver
│   │   └── gold/              # Aggregated → ClickHouse gold
│   ├── macros/
│   ├── dbt_project.yml
│   └── profiles.yml
├── jupyter/
│   └── Dockerfile             # PySpark + ClickHouse + dbt
├── scripts/
│   ├── create-buckets.sh      # Init MinIO
│   ├── init-clickhouse.sh     # Cria databases CH
│   └── init-postgres.sql      # Cria databases PG
└── spark/
    └── notebooks/             # Notebooks PySpark
```

## Adicionar um pipeline novo

1. Configure o conector no **Airbyte** (http://localhost:8000)
2. Crie a tabela de destino no Airbyte apontando para ClickHouse `airbyte_raw`
3. Adicione o source em `dbt/models/sources.yml`
4. Crie modelos em `bronze/`, `silver/`, `gold/`
5. Registre a DAG em `airflow/dags/`

## Segurança (produção)

- Mude **todas** as senhas no `.env`
- Restrinja `listen_host` no ClickHouse para IPs internos
- Habilite TLS no MinIO e ClickHouse
- Use secrets manager (Vault / AWS SM) em vez de `.env` em produção

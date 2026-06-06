.PHONY: help up down restart logs ps reset \
        up-airbyte down-airbyte airbyte-credentials \
        dbt-run dbt-test dbt-docs \
        jupyter spark-ui airflow-ui metabase-ui minio-ui airbyte-ui

COMPOSE       := docker compose -f docker-compose.yml
DBT           := docker compose -f docker-compose.yml run --rm airflow-scheduler \
                 bash -c "cd /opt/airflow/dbt && dbt"

# ─────────────────────────────────────────────
# Help
# ─────────────────────────────────────────────
help: ## Mostra esta ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

# ─────────────────────────────────────────────
# Stack principal
# ─────────────────────────────────────────────
up: ## Sobe toda a stack principal
	$(COMPOSE) up -d --build

down: ## Para toda a stack principal
	$(COMPOSE) down

restart: down up ## Reinicia a stack

logs: ## Tail de todos os logs
	$(COMPOSE) logs -f

ps: ## Lista containers e status
	$(COMPOSE) ps

reset: ## Remove containers, volumes e dados (CUIDADO!)
	$(COMPOSE) down -v --remove-orphans
	@echo "⚠️  Todos os volumes removidos."

# ─────────────────────────────────────────────
# Airbyte (via abctl — docker-compose depreciado desde v1.0)
# ─────────────────────────────────────────────
up-airbyte: ## Instala e sobe o Airbyte via abctl (porta 8000)
	bash scripts/install-airbyte.sh

down-airbyte: ## Para e remove o Airbyte
	abctl local uninstall

airbyte-credentials: ## Mostra as credenciais do Airbyte
	abctl local credentials

# ─────────────────────────────────────────────
# dbt
# ─────────────────────────────────────────────
dbt-deps: ## Instala dependências dbt (packages.yml)
	$(DBT) deps

dbt-run: ## Executa todos os modelos dbt
	$(DBT) run

dbt-run-bronze: ## Executa apenas camada bronze
	$(DBT) run --select tag:bronze

dbt-run-silver: ## Executa apenas camada silver
	$(DBT) run --select tag:silver

dbt-run-gold: ## Executa apenas camada gold
	$(DBT) run --select tag:gold

dbt-test: ## Roda testes dbt
	$(DBT) test

dbt-docs: ## Gera e serve documentação dbt (porta 8085)
	$(DBT) docs generate
	$(DBT) docs serve --port 8085

# ─────────────────────────────────────────────
# Acesso rápido às UIs
# ─────────────────────────────────────────────
airflow-ui: ## Abre Airflow no browser
	open http://localhost:8082

jupyter-ui: ## Abre JupyterLab no browser
	open http://localhost:8888

spark-ui: ## Abre Spark Master UI no browser
	open http://localhost:8080

metabase-ui: ## Abre Metabase no browser
	open http://localhost:3000

minio-ui: ## Abre MinIO Console no browser
	open http://localhost:9001

airbyte-ui: ## Abre Airbyte no browser
	open http://localhost:8000

# ─────────────────────────────────────────────
# Init helpers
# ─────────────────────────────────────────────
init: ## Configura UID do Airflow e copia .env
	@if [ ! -f .env ]; then cp .env.example .env && echo "✅ .env criado a partir do .env.example"; fi
	@echo "AIRFLOW_UID=$$(id -u)" >> .env
	@echo "✅ AIRFLOW_UID configurado"

clickhouse-cli: ## Abre shell interativo do ClickHouse
	$(COMPOSE) exec clickhouse clickhouse-client \
	  --user $${CLICKHOUSE_USER} --password $${CLICKHOUSE_PASSWORD}

minio-mc: ## Abre shell do MinIO mc
	$(COMPOSE) exec minio-init mc --config-dir /tmp/.mc

# Guia de Início — Data Platform

Tempo estimado: **~20 minutos** (excluindo downloads de imagens na primeira vez).

---

## 0. Pré-requisitos

Verifique antes de começar:

```bash
docker --version        # >= 24.0
docker compose version  # >= 2.20
python3 --version       # >= 3.10 (para gerar a Fernet key)
make --version          # qualquer versão
```

**Recursos mínimos da VM:**

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| RAM     | 16 GB  | 32 GB       |
| vCPUs   | 4      | 8           |
| Disco   | 60 GB  | 120 GB      |

---

## 1. Configurar o .env

```bash
cd data-platform
cp .env.example .env
```

Agora gere as chaves obrigatórias do Airflow e preencha o `.env`:

```bash
# Gera a Fernet key (criptografia de credenciais do Airflow)
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# Gera a Secret key (sessão do webserver)
python3 -c "import secrets; print(secrets.token_hex(32))"
```

Edite o `.env` com os valores gerados:

```bash
nano .env   # ou use o editor de sua preferência
```

Campos obrigatórios para alterar:

```env
POSTGRES_PASSWORD=senha_forte_aqui
CLICKHOUSE_PASSWORD=senha_forte_aqui
MINIO_ROOT_PASSWORD=senha_forte_aqui
AIRFLOW_FERNET_KEY=<saída do comando acima>
AIRFLOW_SECRET_KEY=<saída do segundo comando>
AIRFLOW_ADMIN_PASSWORD=senha_forte_aqui
JUPYTER_TOKEN=senha_forte_aqui
```

---

## 2. Inicializar e subir a stack

```bash
# Configura o UID do Airflow com seu usuário local
make init

# Sobe todos os serviços (pode levar 5-10 min no primeiro pull)
make up
```

Acompanhe o progresso:

```bash
make logs
# Ctrl+C para sair dos logs sem parar os containers
```

Verifique se todos subiram:

```bash
make ps
```

Saída esperada — todos os containers devem estar `healthy` ou `running`:

```
NAME                    STATUS
dp-postgres             running (healthy)
dp-redis                running (healthy)
dp-clickhouse           running (healthy)
dp-minio                running (healthy)
dp-minio-init           exited (0)        ← normal, job único
dp-spark-master         running (healthy)
dp-spark-worker         running
dp-jupyter              running
dp-airflow-webserver    running (healthy)
dp-airflow-scheduler    running (healthy)
dp-airflow-worker       running
dp-airflow-triggerer    running
dp-airflow-init         exited (0)        ← normal, job único
dp-metabase             running (healthy)
```

---

## 3. Verificar cada serviço

### 3.1 Airflow — http://localhost:8082

```bash
make airflow-ui
```

- Login: `admin` / senha do `.env` (`AIRFLOW_ADMIN_PASSWORD`)
- Verifique: menu **DAGs** aparece sem erros
- Deve mostrar a DAG `example_pipeline` pausada

### 3.2 MinIO — http://localhost:9001

```bash
make minio-ui
```

- Login: `minioadmin` / `MINIO_ROOT_PASSWORD`
- Verifique: os buckets devem estar criados automaticamente:
  - `raw-landing`, `bronze`, `silver`, `gold`, `spark-checkpoints`, `airbyte-logs`, `dbt-artifacts`

Se os buckets não aparecerem, force a recriação:

```bash
docker compose run --rm minio-init
```

### 3.3 ClickHouse — http://localhost:8123

```bash
# Teste via curl
curl "http://localhost:8123/?user=${CLICKHOUSE_USER}&password=${CLICKHOUSE_PASSWORD}&query=SHOW+DATABASES"
```

Saída esperada:

```
airbyte_raw
bronze
default
gold
silver
system
```

Ou acesse o shell interativo:

```bash
make clickhouse-cli
# Dentro do shell:
SHOW DATABASES;
SELECT version();
```

### 3.4 JupyterLab — http://localhost:8888

```bash
make jupyter-ui
```

- Token: valor de `JUPYTER_TOKEN` no `.env`
- Crie um notebook e teste a conexão com Spark:

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .master("spark://spark-master:7077") \
    .appName("teste-conexao") \
    .getOrCreate()

print(spark.version)  # deve imprimir 4.1.1
spark.stop()
```

### 3.5 Spark UI — http://localhost:8080

```bash
make spark-ui
```

- Verifique: 1 worker registrado (dp-spark-worker)
- Status do worker: `ALIVE`

### 3.6 Metabase — http://localhost:3000

```bash
make metabase-ui
```

Na primeira vez: siga o wizard de configuração.

Conecte ao ClickHouse no wizard (ou depois em **Admin → Databases → Add**):

| Campo    | Valor                    |
|----------|--------------------------|
| Tipo     | ClickHouse               |
| Host     | `clickhouse`             |
| Porta    | `8123`                   |
| Database | `gold`                   |
| Usuário  | valor de `CLICKHOUSE_USER`|
| Senha    | valor de `CLICKHOUSE_PASSWORD`|

---

## 4. Instalar o Airbyte (via abctl)

> O Airbyte usa Kubernetes local (k3d). Precisa de ~4 GB adicionais de RAM.

```bash
make up-airbyte
```

O script instala o `abctl` automaticamente e sobe o Airbyte. Pode levar 5-10 minutos.

Após concluir:

```bash
# Veja as credenciais geradas automaticamente
make airbyte-credentials
```

Acesse:

```bash
make airbyte-ui   # http://localhost:8000
```

**Configurar destino ClickHouse no Airbyte:**

1. **Destinations → New destination → ClickHouse**
2. Preencha:
   - Host: `host.docker.internal`
   - Port: `8123`
   - Database: `airbyte_raw`
   - Username/Password: do `.env`

---

## 5. Rodar o dbt

```bash
# Instala dependências do dbt (dbt_utils, dbt_expectations)
make dbt-deps

# Roda os modelos de exemplo (bronze → silver → gold)
make dbt-run

# Executa os testes de qualidade de dados
make dbt-test
```

Saída esperada no `dbt-run`:

```
Running with dbt=1.10.0
Found 3 models, 4 tests, 0 snapshots

Completed successfully

Done. PASS=3 WARN=0 ERROR=0 SKIP=0 TOTAL=3
```

Para ver a documentação interativa:

```bash
make dbt-docs
# Abre em http://localhost:8085
```

---

## 6. Teste end-to-end com dados de exemplo

Este teste simula um pipeline completo usando dados dummy sem precisar do Airbyte.

### 6.1 Inserir dados no ClickHouse (simula chegada do Airbyte)

```bash
make clickhouse-cli
```

```sql
-- Cria tabela de exemplo na camada raw
CREATE TABLE IF NOT EXISTS airbyte_raw.example_table (
    id           UInt64,
    raw_data     String,
    source_system String,
    _airbyte_extracted_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id;

-- Insere dados de teste
INSERT INTO airbyte_raw.example_table (id, raw_data, source_system)
VALUES
    (1, 'cliente: João Silva, valor: 150.00', 'erp'),
    (2, 'cliente: Maria Costa, valor: 320.50', 'erp'),
    (3, 'produto: Notebook, estoque: 42', 'wms'),
    (4, 'produto: Mouse, estoque: 180', 'wms');

-- Confirma
SELECT * FROM airbyte_raw.example_table;
```

### 6.2 Rodar o pipeline dbt

```bash
make dbt-run
```

### 6.3 Verificar o resultado no ClickHouse

```bash
make clickhouse-cli
```

```sql
-- Camada bronze (dados brutos copiados)
SELECT * FROM bronze.bronze_example;

-- Camada silver (dados limpos)
SELECT * FROM silver.silver_example;

-- Camada gold (agregação diária — aparece no Metabase)
SELECT * FROM gold.gold_example_daily;
```

### 6.4 Visualizar no Metabase

1. Acesse http://localhost:3000
2. **New → Question**
3. Selecione o banco `gold`
4. Escolha a tabela `gold_example_daily`
5. Clique em **Visualize** — você verá os dados agregados

---

## 7. Disparar a DAG de exemplo no Airflow

1. Acesse http://localhost:8082
2. Localize a DAG `example_pipeline`
3. Toggle para **ativar** (botão à esquerda do nome)
4. Clique em ▶ **Trigger DAG**
5. Acompanhe as tasks em **Graph View**

> A DAG de exemplo usa o Airbyte e o Spark, então requer que ambos estejam up. Para teste sem eles, edite a DAG descomentando apenas as tasks dbt.

---

## 8. Comandos úteis do dia a dia

```bash
# Ver status de todos os containers
make ps

# Parar tudo (sem apagar dados)
make down

# Reiniciar um serviço específico
docker compose restart dp-airflow-scheduler

# Ver logs de um serviço
docker compose logs -f dp-clickhouse

# Abrir shell no container do Airflow
docker compose exec dp-airflow-scheduler bash

# Resetar tudo (APAGA TODOS OS DADOS)
make reset
```

---

## 9. Solução de problemas comuns

**Airflow não inicia / erro de migração:**

```bash
docker compose logs dp-airflow-init
# Se necessário, force a migração:
docker compose run --rm airflow-init
```

**ClickHouse sem os databases bronze/silver/gold:**

```bash
docker compose exec dp-clickhouse bash /docker-entrypoint-initdb.d/init.sh
```

**MinIO sem buckets:**

```bash
docker compose run --rm minio-init
```

**JupyterLab não conecta no Spark:**
Verifique se o `spark-master` está healthy: `make ps`.
O `SPARK_MASTER` no Jupyter deve ser `spark://spark-master:7077`.

**Airbyte trava na instalação:**

```bash
abctl local status     # verifica estado do k3d
abctl local uninstall  # limpa e tenta novamente
make up-airbyte
```

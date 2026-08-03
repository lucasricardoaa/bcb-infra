# Diagrama de Arquitetura — bcb-infra

## Visão geral

```
+------------------------------------------------------------------+
|                        GitHub                                    |
|                                                                  |
|  bcb-infra (este repo)     bcb-pipeline          bcb-warehouse  |
|  +------------------+      +--------------+      +------------+ |
|  | terraform/       |      | dags/        |      | dbt/       | |
|  | modules/         |      | lambdas/     |      | glue/      | |
|  | .github/         |      | tests/       |      | dags/      | |
|  +--------+---------+      +--------------+      +------------+ |
|           |                                                      |
|     PR → plan                                                    |
|     merge → apply                                                |
+-----------|------------------------------------------------------+
            |
            | OIDC (sem credenciais estáticas)
            v
+------------------------------------------------------------------+
|                        AWS (us-east-1)                           |
|                                                                  |
|  +---------------------------------+                             |
|  | IAM                             |                             |
|  | bcb-github-actions-oidc         | <-- role assumida pelo CI/CD|
|  | bcb-glue-role                   |                             |
|  | bcb-lambda-role                 |                             |
|  | bcb-pipeline-dev (user)         |                             |
|  +---------------------------------+                             |
|                                                                  |
|  Buckets S3                         Glue Data Catalog           |
|  +------------------------+         +-------------------------+  |
|  | bcb-pipeline-raw       |         | database: bcb_pipeline  |  |
|  |  bcb/1/year=.../       |         |   tabelas: usd_brl      |  |
|  |  bcb/11/year=.../      | ------> |            selic        |  |
|  |  bcb/433/year=.../     |         |            ipca         |  |
|  +------------------------+         | database: bcb_warehouse |  |
|  | bcb-pipeline-staging   |         |   tabelas: stg_*, fct_* |  |
|  |  bcb/1/year=.../       |         |            dim_*, int_* |  |
|  +------------------------+         +-------------------------+  |
|  | bcb-pipeline-analytics |                    |                 |
|  |  athena-results/       |              queries via             |
|  +------------------------+                    v                 |
|  | bcb-warehouse          |         +-------------------------+  |
|  |  warehouse/            | <------ | Athena                  |  |
|  |  glue/scripts/         |         | workgroup: bcb-dbt      |  |
|  |  glue/temp/            |         | output: bcb-warehouse/  |  |
|  |  athena-results/       |         |         athena-results/ |  |
|  +------------------------+         +-------------------------+  |
|                                                                  |
|  Glue ETL                                                        |
|  +------------------------------+                                |
|  | bcb-staging-transform        |                                |
|  | Glue 4.0 / Iceberg / G.1X×2  |                               |
|  | staging → warehouse Iceberg  |                                |
|  +------------------------------+                                |
|                                                                  |
|  Lambda (fora do escopo bcb-infra — ver ADR-0003)               |
|  +---------------------------+   ECR                            |
|  | bcb-raw-to-staging        |   +-------------------+          |
|  | (pertence ao bcb-pipeline)|   | bcb-pipeline:prod |          |
|  +---------------------------+   +-------------------+          |
|                                                                  |
|  Secrets Manager                  Backend Terraform             |
|  +------------------------------+ +-------------------------+   |
|  | bcb/dbt/athena-config        | | S3: bcb-infra-terraform |   |
|  | bcb/airflow/aws-credentials  | |     -state              |   |
|  | (valores preenchidos manual) | | DynamoDB: bcb-infra-    |   |
|  +------------------------------+ |     terraform-locks     |   |
|                                   +-------------------------+   |
|                                                                  |
+------------------------------------------------------------------+
```

## Fluxo de dados

```
BCB API
  |
  | (bcb-pipeline — Airflow + Lambda)
  v
bcb-pipeline-raw (JSON)
  |
  | Lambda bcb-raw-to-staging
  v
bcb-pipeline-staging (Parquet/Snappy)
  |
  | Glue Job bcb-staging-transform (PySpark + Iceberg)
  v
bcb-warehouse/warehouse/intermediate/ (Iceberg)
  |
  | dbt-core via Athena (workgroup bcb-dbt)
  v
bcb-warehouse/warehouse/mart/ (Iceberg — star schema)
  fct_cotacoes_diarias, fct_indicadores_mensais
  dim_serie, dim_data
```

## O que o bcb-infra gerencia

```
bcb-infra (Terraform)
  |
  +-- Importa recursos existentes (bcb-pipeline)
  |     - Buckets S3: bcb-pipeline-raw, bcb-pipeline-staging, bcb-pipeline-analytics
  |     - IAM user: bcb-pipeline-dev + policies deploy e runtime
  |     - IAM role: bcb-lambda-role + inline policies
  |     - Glue database: bcb_pipeline + tabelas usd_brl, selic, ipca
  |
  +-- Cria novos recursos (bcb-warehouse)
  |     - Bucket S3: bcb-warehouse
  |     - IAM role: bcb-glue-role
  |     - Glue database: bcb_warehouse
  |     - Glue Job: bcb-staging-transform
  |     - Athena workgroup: bcb-dbt
  |     - Secrets Manager: bcb/dbt/athena-config, bcb/airflow/aws-credentials
  |
  +-- Cria infraestrutura de plataforma
        - OIDC provider: token.actions.githubusercontent.com
        - IAM role: bcb-github-actions-oidc
```

## CI/CD

```
Pull Request aberto
  --> trigger: terraform-plan.yml
        fmt check --> init --> validate --> plan -out=tfplan
        resultado postado como comentário no PR

Merge em main
  --> trigger: terraform-apply.yml
        init --> plan -out=tfplan --> apply tfplan
        environment: production (requer aprovação manual no GitHub)
```

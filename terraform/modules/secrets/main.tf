# Módulo Secrets — segredos no AWS Secrets Manager
# Valores criados vazios ("{}") — preenchimento manual após apply (ADR-0006)

resource "aws_secretsmanager_secret" "dbt_athena_config" {
  name        = "bcb/dbt/athena-config"
  description = "Configurações de conexão do dbt-core com o Athena (workgroup, database, s3_staging_dir)"

  tags = {
    Project   = "bcb-warehouse"
    ManagedBy = "bcb-infra"
  }
}

resource "aws_secretsmanager_secret_version" "dbt_athena_config" {
  secret_id     = aws_secretsmanager_secret.dbt_athena_config.id
  secret_string = "{}"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "airflow_aws_credentials" {
  name        = "bcb/airflow/aws-credentials"
  description = "Credenciais AWS usadas pelo Airflow para acionar os pipelines bcb"

  tags = {
    Project   = "bcb-pipeline"
    ManagedBy = "bcb-infra"
  }
}

resource "aws_secretsmanager_secret_version" "airflow_aws_credentials" {
  secret_id     = aws_secretsmanager_secret.airflow_aws_credentials.id
  secret_string = "{}"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

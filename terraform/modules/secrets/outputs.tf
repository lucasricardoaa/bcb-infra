output "dbt_athena_config_arn" {
  description = "ARN do secret bcb/dbt/athena-config"
  value       = aws_secretsmanager_secret.dbt_athena_config.arn
}

output "airflow_aws_credentials_arn" {
  description = "ARN do secret bcb/airflow/aws-credentials"
  value       = aws_secretsmanager_secret.airflow_aws_credentials.arn
}

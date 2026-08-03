# Outputs globais do bcb-infra

output "github_actions_role_arn" {
  description = "ARN da role OIDC para o GitHub Actions — usar nos workflows como role-to-assume"
  value       = module.iam.github_actions_role_arn
}

output "athena_dbt_workgroup" {
  description = "Nome do workgroup Athena do dbt"
  value       = module.athena.dbt_workgroup_name
}

output "secret_dbt_athena_config_arn" {
  description = "ARN do secret bcb/dbt/athena-config — preencher manualmente no console"
  value       = module.secrets.dbt_athena_config_arn
}

output "secret_airflow_aws_credentials_arn" {
  description = "ARN do secret bcb/airflow/aws-credentials — preencher manualmente no console"
  value       = module.secrets.airflow_aws_credentials_arn
}

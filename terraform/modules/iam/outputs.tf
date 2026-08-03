# Outputs do módulo IAM

output "pipeline_dev_arn" {
  description = "ARN do IAM user bcb-pipeline-dev"
  value       = aws_iam_user.pipeline_dev.arn
}

output "pipeline_deploy_policy_arn" {
  description = "ARN da policy bcb-pipeline-deploy"
  value       = aws_iam_policy.pipeline_deploy.arn
}

output "pipeline_runtime_policy_arn" {
  description = "ARN da policy bcb-pipeline-runtime"
  value       = aws_iam_policy.pipeline_runtime.arn
}

output "lambda_role_arn" {
  description = "ARN da role bcb-lambda-role"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_role_name" {
  description = "Nome da role bcb-lambda-role"
  value       = aws_iam_role.lambda_role.name
}

output "glue_role_arn" {
  description = "ARN da role bcb-glue-role"
  value       = aws_iam_role.glue_role.arn
}

output "glue_role_name" {
  description = "Nome da role bcb-glue-role"
  value       = aws_iam_role.glue_role.name
}

output "github_actions_role_arn" {
  description = "ARN da role OIDC para o GitHub Actions"
  value       = aws_iam_role.github_actions_oidc.arn
}

output "github_oidc_provider_arn" {
  description = "ARN do OIDC provider do GitHub"
  value       = aws_iam_openid_connect_provider.github.arn
}

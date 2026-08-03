output "dbt_workgroup_name" {
  description = "Nome do workgroup Athena do dbt"
  value       = aws_athena_workgroup.dbt.name
}

output "dbt_workgroup_arn" {
  description = "ARN do workgroup Athena do dbt"
  value       = aws_athena_workgroup.dbt.arn
}

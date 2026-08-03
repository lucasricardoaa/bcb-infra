# Outputs do módulo Glue

output "glue_database_pipeline_name" {
  description = "Nome do database Glue bcb_pipeline (importado do bcb-pipeline)"
  value       = aws_glue_catalog_database.pipeline.name
}

output "glue_database_warehouse_name" {
  description = "Nome do database Glue bcb_warehouse (bcb-warehouse)"
  value       = aws_glue_catalog_database.warehouse.name
}

output "glue_job_staging_transform_name" {
  description = "Nome do Glue Job bcb-staging-transform"
  value       = aws_glue_job.staging_transform.name
}

# Outputs do módulo S3

output "bucket_pipeline_raw_arn" {
  description = "ARN do bucket S3 da camada raw (bcb-pipeline)"
  value       = aws_s3_bucket.pipeline_raw.arn
}

output "bucket_pipeline_staging_arn" {
  description = "ARN do bucket S3 da camada staging (bcb-pipeline)"
  value       = aws_s3_bucket.pipeline_staging.arn
}

output "bucket_pipeline_analytics_arn" {
  description = "ARN do bucket S3 da camada analytics (bcb-pipeline)"
  value       = aws_s3_bucket.pipeline_analytics.arn
}

output "bucket_warehouse_arn" {
  description = "ARN do bucket S3 do bcb-warehouse"
  value       = aws_s3_bucket.warehouse.arn
}

output "bucket_pipeline_raw_id" {
  description = "Nome do bucket S3 da camada raw"
  value       = aws_s3_bucket.pipeline_raw.id
}

output "bucket_pipeline_staging_id" {
  description = "Nome do bucket S3 da camada staging"
  value       = aws_s3_bucket.pipeline_staging.id
}

output "bucket_pipeline_analytics_id" {
  description = "Nome do bucket S3 da camada analytics"
  value       = aws_s3_bucket.pipeline_analytics.id
}

output "bucket_warehouse_id" {
  description = "Nome do bucket S3 do bcb-warehouse"
  value       = aws_s3_bucket.warehouse.id
}

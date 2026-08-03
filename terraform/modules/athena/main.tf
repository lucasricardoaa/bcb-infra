# Módulo Athena — workgroup do dbt com guardrail de custo

resource "aws_athena_workgroup" "dbt" {
  name        = "bcb-dbt"
  description = "Workgroup dedicado às queries do dbt-core sobre o bcb-warehouse"
  state       = "ENABLED"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false
    bytes_scanned_cutoff_per_query     = 1073741824 # 1 GB — guardrail de custo

    result_configuration {
      output_location = "s3://bcb-warehouse/athena-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = {
    Project   = "bcb-warehouse"
    ManagedBy = "bcb-infra"
  }
}

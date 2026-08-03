# Lifecycle rules dos buckets S3
#
# Regras aplicadas:
#   - bcb-pipeline-analytics: expiração de objetos em athena-results/ após 7 dias
#   - bcb-warehouse: expiração de objetos em athena-results/ após 7 dias
#
# Buckets raw e staging não possuem lifecycle configurado (alinhado ao estado real na AWS).

resource "aws_s3_bucket_lifecycle_configuration" "pipeline_analytics" {
  bucket = aws_s3_bucket.pipeline_analytics.id

  rule {
    id     = "expire-athena-results"
    status = "Enabled"

    filter {
      prefix = "athena-results/"
    }

    expiration {
      days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "warehouse" {
  bucket = aws_s3_bucket.warehouse.id

  rule {
    id     = "expire-athena-results"
    status = "Enabled"

    filter {
      prefix = "athena-results/"
    }

    expiration {
      days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "expire-glue-temp"
    status = "Enabled"

    filter {
      prefix = "glue/temp/"
    }

    expiration {
      days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "expire-glue-logs"
    status = "Enabled"

    filter {
      prefix = "glue/logs/"
    }

    expiration {
      days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

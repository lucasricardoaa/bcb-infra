# Módulo S3 — buckets do bcb-pipeline (importados) e bcb-warehouse (novo)
#
# Buckets importados do bcb-pipeline:
#   - bcb-pipeline-raw
#   - bcb-pipeline-staging
#   - bcb-pipeline-analytics
#
# Bucket novo (criado via apply):
#   - bcb-warehouse

# ---------------------------------------------------------------------------
# bcb-pipeline-raw
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "pipeline_raw" {
  bucket = "bcb-pipeline-raw"

  tags = {
    Project     = "bcb-pipeline"
    ManagedBy   = "bcb-infra"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "pipeline_raw" {
  bucket = aws_s3_bucket.pipeline_raw.id

  versioning_configuration {
    # Buckets criados sem versioning habilitado retornam "Disabled" na AWS.
    # "Suspended" só é válido após versioning ter sido habilitado previamente.
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_raw" {
  bucket = aws_s3_bucket.pipeline_raw.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_raw" {
  bucket = aws_s3_bucket.pipeline_raw.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    # bucket_key_enabled só tem efeito com SSE-KMS; com AES256 é ignorado pela AWS.
    # Mantido explicitamente para evitar diff após import.
    bucket_key_enabled = false
  }
}

# ---------------------------------------------------------------------------
# bcb-pipeline-staging
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "pipeline_staging" {
  bucket = "bcb-pipeline-staging"

  tags = {
    Project     = "bcb-pipeline"
    ManagedBy   = "bcb-infra"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "pipeline_staging" {
  bucket = aws_s3_bucket.pipeline_staging.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_staging" {
  bucket = aws_s3_bucket.pipeline_staging.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_staging" {
  bucket = aws_s3_bucket.pipeline_staging.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    # bucket_key_enabled só tem efeito com SSE-KMS; com AES256 é ignorado pela AWS.
    # Mantido explicitamente para evitar diff após import.
    bucket_key_enabled = false
  }
}

# ---------------------------------------------------------------------------
# bcb-pipeline-analytics
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "pipeline_analytics" {
  bucket = "bcb-pipeline-analytics"

  tags = {
    Project     = "bcb-pipeline"
    ManagedBy   = "bcb-infra"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "pipeline_analytics" {
  bucket = aws_s3_bucket.pipeline_analytics.id

  versioning_configuration {
    # Versionamento desabilitado intencionalmente: dados de output do Athena
    # são regeneráveis a qualquer momento via re-execução de query.
    # Buckets criados sem versionamento retornam "Disabled" na API da AWS.
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_analytics" {
  bucket = aws_s3_bucket.pipeline_analytics.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_analytics" {
  bucket = aws_s3_bucket.pipeline_analytics.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    # bucket_key_enabled só tem efeito com SSE-KMS; com AES256 é ignorado pela AWS.
    # Mantido explicitamente para evitar diff após import.
    bucket_key_enabled = false
  }
}

# ---------------------------------------------------------------------------
# bcb-warehouse (novo — criado via terraform apply)
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "warehouse" {
  bucket = "bcb-warehouse"

  tags = {
    Project     = "bcb-warehouse"
    ManagedBy   = "bcb-infra"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "warehouse" {
  bucket = aws_s3_bucket.warehouse.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "warehouse" {
  bucket = aws_s3_bucket.warehouse.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "warehouse" {
  bucket = aws_s3_bucket.warehouse.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    # bucket_key_enabled só tem efeito com SSE-KMS; com AES256 é ignorado pela AWS.
    # Mantido explicitamente para evitar diff após import.
    bucket_key_enabled = false
  }
}

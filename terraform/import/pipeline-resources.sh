#!/usr/bin/env bash
# pipeline-resources.sh
# Importa recursos existentes do bcb-pipeline para o state do Terraform.
# Execute após `terraform init` e antes do primeiro `terraform apply`.
#
# IMPORTANTE: Os blocos `resource` correspondentes devem estar definidos em
# terraform/modules/ antes de executar cada comando de import.
# Execute um grupo por vez e verifique o plan antes de prosseguir.
#
# Referência: ADR-0003 — Escopo do bcb-infra

set -euo pipefail

AWS_ACCOUNT_ID="992382708036"
REGION="us-east-1"
PREFIX="bcb"

echo "=== Import de recursos existentes do bcb-pipeline ==="
echo ""

# ---------------------------------------------------------------------------
# Fase A — Buckets S3
# Execute após implementar terraform/modules/s3/main.tf
# ---------------------------------------------------------------------------

echo "[S3] Importando buckets do bcb-pipeline..."

# Bucket da camada raw
terraform -chdir=terraform import \
  module.s3.aws_s3_bucket.raw \
  "${PREFIX}-raw-data"

# Bucket da camada staging
terraform -chdir=terraform import \
  module.s3.aws_s3_bucket.staging \
  "${PREFIX}-staging-data"

# Bucket da camada analytics
terraform -chdir=terraform import \
  module.s3.aws_s3_bucket.analytics \
  "${PREFIX}-analytics-data"

# ---------------------------------------------------------------------------
# Fase B — Roles IAM
# Execute após implementar terraform/modules/iam/main.tf
# ---------------------------------------------------------------------------

echo "[IAM] Importando roles do bcb-pipeline..."

# Role do Glue crawler
terraform -chdir=terraform import \
  module.iam.aws_iam_role.glue_crawler \
  "${PREFIX}-glue-crawler-role"

# ---------------------------------------------------------------------------
# Fase C — Glue Data Catalog
# Execute após implementar terraform/modules/glue/main.tf
# ---------------------------------------------------------------------------

echo "[Glue] Importando databases do Glue Data Catalog..."

# Database da camada raw
terraform -chdir=terraform import \
  module.glue.aws_glue_catalog_database.raw \
  "${AWS_ACCOUNT_ID}:${PREFIX}_raw"

# Database da camada staging
terraform -chdir=terraform import \
  module.glue.aws_glue_catalog_database.staging \
  "${AWS_ACCOUNT_ID}:${PREFIX}_staging"

# Database da camada analytics
terraform -chdir=terraform import \
  module.glue.aws_glue_catalog_database.analytics \
  "${AWS_ACCOUNT_ID}:${PREFIX}_analytics"

echo ""
echo "=== Import concluido! ==="
echo "Execute 'terraform plan' para verificar divergências antes do apply."

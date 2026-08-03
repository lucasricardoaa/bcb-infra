# Orquestrador principal do bcb-infra
# Este arquivo chama os módulos por serviço AWS e passa as variáveis necessárias.
# Os blocos de módulo são habilitados progressivamente nas fases de implementação.

# ---------------------------------------------------------------------------
# Módulo S3 — buckets das camadas raw, staging e analytics (bcb-pipeline)
# e bucket do bcb-warehouse (novo)
# ---------------------------------------------------------------------------
module "s3" {
  source      = "./modules/s3"
  environment = var.environment
}

# ---------------------------------------------------------------------------
# Módulo IAM — user e policies do bcb-pipeline-dev, role bcb-lambda-role
# ---------------------------------------------------------------------------
module "iam" {
  source               = "./modules/iam"
  aws_account_id       = var.aws_account_id
  github_org           = var.github_org
  github_user_id       = var.github_user_id
  github_repo_infra    = var.github_repo_infra
  github_repo_infra_id = var.github_repo_infra_id
}

# ---------------------------------------------------------------------------
# Módulo Glue — Data Catalog databases, tabelas (bcb_pipeline) e Glue Job
# ---------------------------------------------------------------------------
module "glue" {
  source        = "./modules/glue"
  glue_role_arn = module.iam.glue_role_arn
}

# ---------------------------------------------------------------------------
# Módulo Athena — workgroup e configurações de query
# ---------------------------------------------------------------------------
module "athena" {
  source = "./modules/athena"
}

# ---------------------------------------------------------------------------
# Módulo Secrets — segredos no AWS Secrets Manager
# ---------------------------------------------------------------------------
module "secrets" {
  source = "./modules/secrets"
}

# ---------------------------------------------------------------------------
# Módulo Billing — AWS Budget com alerta de custo mensal
# ---------------------------------------------------------------------------
module "billing" {
  source      = "./modules/billing"
  alert_email = var.alert_email
}

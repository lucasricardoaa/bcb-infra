# Módulo IAM — recursos do bcb-pipeline importados e futuros recursos do bcb-warehouse
#
# Recursos importados do bcb-pipeline:
#   - aws_iam_user.pipeline_dev             (bcb-pipeline-dev)
#   - aws_iam_policy.pipeline_deploy        (bcb-pipeline-deploy, versão v2)
#   - aws_iam_policy.pipeline_runtime       (bcb-pipeline-runtime, versão v1)
#   - aws_iam_user_policy_attachment.deploy
#   - aws_iam_user_policy_attachment.runtime
#   - aws_iam_role.lambda_role              (bcb-lambda-role)
#   - aws_iam_role_policy.lambda_raw_read   (inline: bcb-lambda-raw-read)
#   - aws_iam_role_policy.lambda_staging_write (inline: bcb-lambda-staging-write)

# ---------------------------------------------------------------------------
# IAM User — bcb-pipeline-dev
# ---------------------------------------------------------------------------

resource "aws_iam_user" "pipeline_dev" {
  name = "bcb-pipeline-dev"
  path = "/"

  tags = {
    # Tag original criada pelo bcb-pipeline com a access key ID como chave.
    # Preservada para evitar diff no plan. Não remover sem análise de impacto.
    "AKIA6ODU6NFCENGTJ7HK" = "claude development projects"
    Project                 = "bcb-pipeline"
    ManagedBy               = "bcb-infra"
  }
}

# ---------------------------------------------------------------------------
# IAM Managed Policies
# ---------------------------------------------------------------------------

resource "aws_iam_policy" "pipeline_deploy" {
  name   = "bcb-pipeline-deploy"
  path   = "/"
  # description omitido intencionalmente: a policy foi criada sem description na AWS.
  # Adicionar description em uma policy existente força destroy+create (campo imutável).
  policy = templatefile("${path.module}/policies/bcb-pipeline-deploy.json", {
    account_id = var.aws_account_id
  })

  tags = {
    Project   = "bcb-pipeline"
    ManagedBy = "bcb-infra"
  }
}

resource "aws_iam_policy" "pipeline_runtime" {
  name   = "bcb-pipeline-runtime"
  path   = "/"
  # description omitido intencionalmente: mesma razão acima.
  policy = templatefile("${path.module}/policies/bcb-pipeline-runtime.json", {
    account_id = var.aws_account_id
  })

  tags = {
    Project   = "bcb-pipeline"
    ManagedBy = "bcb-infra"
  }
}

# ---------------------------------------------------------------------------
# Policy Attachments — user bcb-pipeline-dev
# ---------------------------------------------------------------------------

resource "aws_iam_user_policy_attachment" "deploy" {
  user       = aws_iam_user.pipeline_dev.name
  policy_arn = aws_iam_policy.pipeline_deploy.arn
}

resource "aws_iam_user_policy_attachment" "runtime" {
  user       = aws_iam_user.pipeline_dev.name
  policy_arn = aws_iam_policy.pipeline_runtime.arn
}

# ---------------------------------------------------------------------------
# IAM Role — bcb-lambda-role
# ---------------------------------------------------------------------------

resource "aws_iam_role" "lambda_role" {
  name        = "bcb-lambda-role"
  path        = "/"
  description = "Allows Lambda functions to call AWS services on your behalf."

  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project   = "bcb-pipeline"
    ManagedBy = "bcb-infra"
  }
}

# ---------------------------------------------------------------------------
# Inline Policies — bcb-lambda-role
# ---------------------------------------------------------------------------

resource "aws_iam_role_policy" "lambda_raw_read" {
  name   = "bcb-lambda-raw-read"
  role   = aws_iam_role.lambda_role.id
  policy = file("${path.module}/policies/bcb-lambda-raw-read.json")
}

resource "aws_iam_role_policy" "lambda_staging_write" {
  name   = "bcb-lambda-staging-write"
  role   = aws_iam_role.lambda_role.id
  policy = file("${path.module}/policies/bcb-lambda-staging-write.json")
}

# ---------------------------------------------------------------------------
# IAM Role — bcb-glue-role (bcb-warehouse Glue Job)
# ---------------------------------------------------------------------------

resource "aws_iam_role" "glue_role" {
  name        = "bcb-glue-role"
  path        = "/"
  description = "Allows Glue jobs to read from bcb-pipeline-staging and write to bcb-warehouse."

  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project   = "bcb-warehouse"
    ManagedBy = "bcb-infra"
  }
}

resource "aws_iam_role_policy" "glue_role_policy" {
  name   = "bcb-glue-role-policy"
  role   = aws_iam_role.glue_role.id
  policy = templatefile("${path.module}/policies/bcb-glue-role-policy.json", {
    account_id = var.aws_account_id
  })
}

# ---------------------------------------------------------------------------
# OIDC — GitHub Actions → AWS (sem secrets hardcoded)
# ---------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # Thumbprint gerenciado automaticamente pela AWS desde 2023;
  # valor abaixo é o well-known fingerprint do CA intermediário do GitHub.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Project   = "bcb-infra"
    ManagedBy = "bcb-infra"
  }
}

resource "aws_iam_role" "github_actions_oidc" {
  name        = "bcb-github-actions-oidc"
  description = "Role assumida pelo GitHub Actions via OIDC para executar o Terraform do bcb-infra"

  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Novo formato de sub claim do GitHub OIDC (desde 2025): inclui IDs numéricos.
            # Formato: repo:ORG@USER_ID/REPO@REPO_ID:ref_or_environment
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}@${var.github_user_id}/${var.github_repo_infra}@${var.github_repo_infra_id}:*"
          }
        }
      }
    ]
  })

  tags = {
    Project   = "bcb-infra"
    ManagedBy = "bcb-infra"
  }
}

resource "aws_iam_role_policy" "github_actions_oidc_policy" {
  name   = "bcb-github-actions-policy"
  role   = aws_iam_role.github_actions_oidc.id
  policy = templatefile("${path.module}/policies/bcb-github-actions-policy.json", {
    account_id = var.aws_account_id
  })
}

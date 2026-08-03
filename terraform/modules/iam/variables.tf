# Variáveis do módulo IAM

variable "aws_account_id" {
  description = "ID da conta AWS"
  type        = string
}

variable "github_org" {
  description = "Organização ou usuário GitHub (usado na trust policy OIDC)"
  type        = string
}

variable "github_repo_infra" {
  description = "Nome do repositório GitHub do bcb-infra (usado na trust policy OIDC)"
  type        = string
}

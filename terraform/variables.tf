# Variáveis globais do projeto bcb-infra
# Valores padrão refletem o ambiente de produção da conta AWS do portfólio

variable "aws_region" {
  description = "Região AWS onde os recursos serão provisionados"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "ID da conta AWS do portfólio"
  type        = string
  # Sem default — deve ser fornecido explicitamente em terraform.tfvars (gitignored)
}

variable "project_prefix" {
  description = "Prefixo usado na nomenclatura de todos os recursos do projeto"
  type        = string
  default     = "bcb"
}

variable "environment" {
  description = "Ambiente de deploy (prod, staging, dev)"
  type        = string
  default     = "prod"
}

variable "github_org" {
  description = "Organização ou usuário GitHub dono do repositório (usado na trust policy OIDC)"
  type        = string
  # Sem default — deve ser fornecido explicitamente em terraform.tfvars
}

variable "github_repo_infra" {
  description = "Nome do repositório GitHub do bcb-infra (usado na trust policy OIDC)"
  type        = string
  default     = "bcb-infra"
}

variable "alert_email" {
  description = "Email para receber alertas de custo do AWS Budget"
  type        = string
  # Sem default — deve ser fornecido em terraform.tfvars (gitignored)
}

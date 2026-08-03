# Variáveis do módulo Glue

variable "glue_role_arn" {
  description = "ARN da IAM role para o Glue Job (bcb-glue-role, definida no módulo iam)"
  type        = string
}

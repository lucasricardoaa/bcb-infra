#!/usr/bin/env bash
# bootstrap-backend.sh
# Cria o bucket S3 e a tabela DynamoDB necessários para o backend remoto do Terraform.
# Execute este script UMA ÚNICA VEZ antes de rodar `terraform init`.
#
# Pré-requisitos:
#   - AWS CLI configurado com credenciais que tenham permissão para criar S3 e DynamoDB
#   - Perfil AWS CLI: bcb-infra-admin (usuário bcb-infra-terraform com permissões admin)

set -euo pipefail

# ---------------------------------------------------------------------------
# Configurações
# ---------------------------------------------------------------------------
BUCKET_NAME="bcb-infra-terraform-state"
DYNAMODB_TABLE="bcb-infra-terraform-locks"
REGION="us-east-1"
AWS_PROFILE_BOOTSTRAP="bcb-infra-admin"

echo "=== Bootstrap do backend Terraform do bcb-infra ==="
echo "Bucket:         ${BUCKET_NAME}"
echo "DynamoDB table: ${DYNAMODB_TABLE}"
echo "Região:         ${REGION}"
echo "Perfil AWS CLI: ${AWS_PROFILE_BOOTSTRAP}"
echo ""

# ---------------------------------------------------------------------------
# 1. Criar bucket S3
# ---------------------------------------------------------------------------
echo "[1/4] Criando bucket S3..."
aws s3api create-bucket \
  --bucket "${BUCKET_NAME}" \
  --region "${REGION}" \
  --profile "${AWS_PROFILE_BOOTSTRAP}"

echo "[2/4] Habilitando versionamento no bucket..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled \
  --profile "${AWS_PROFILE_BOOTSTRAP}"

echo "[3/4] Bloqueando acesso público ao bucket..."
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --profile "${AWS_PROFILE_BOOTSTRAP}"

# ---------------------------------------------------------------------------
# 2. Criar tabela DynamoDB para lock de state
# ---------------------------------------------------------------------------
echo "[4/4] Criando tabela DynamoDB para locks..."
aws dynamodb create-table \
  --table-name "${DYNAMODB_TABLE}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${REGION}" \
  --profile "${AWS_PROFILE_BOOTSTRAP}"

echo ""
echo "=== Bootstrap concluido com sucesso! ==="
echo ""
echo "Proximos passos:"
echo "  1. Acesse o diretório terraform/:"
echo "       cd terraform/"
echo "  2. Execute o init apontando para o backend remoto:"
echo "       AWS_PROFILE=bcb-infra-admin terraform init"
echo "  3. Verifique que o state foi criado no bucket:"
echo "       aws --profile bcb-infra-admin s3 ls s3://${BUCKET_NAME}/"

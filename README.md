# bcb-infra

Infraestrutura como código (Terraform + GitHub Actions) para os projetos do portfólio BCB.

Provisiona e gerencia os recursos AWS dos Projetos 1 (bcb-pipeline) e 2 (bcb-warehouse):
buckets S3, Glue Data Catalog, Athena, IAM roles e Secrets Manager.

## Arquitetura

Ver `docs/architecture/diagrama.md` para o diagrama completo.

## Pré-requisitos

- Terraform >= 1.9
- AWS CLI configurado com o perfil `bcb-infra-admin` (apenas para execução local)
- Conta AWS na região `us-east-1`

## Como usar

### 1. Bootstrap do backend (uma única vez)

Antes do primeiro `terraform init`, o bucket S3 e a tabela DynamoDB do backend precisam existir:

```bash
bash scripts/bootstrap-backend.sh
```

### 2. Configurar variáveis

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Editar terraform.tfvars e preencher github_org
```

### 3. Init

```bash
cd terraform/
terraform init
```

### 4. Plan

```bash
terraform plan
```

### 5. Apply

```bash
terraform apply
```

## Módulos

| Módulo | Responsabilidade |
|---|---|
| `modules/s3` | Buckets S3 das camadas raw, staging, analytics e warehouse |
| `modules/iam` | Roles IAM para Glue, Athena e autenticação OIDC do GitHub Actions |
| `modules/glue` | Glue Data Catalog: databases, tabelas e Glue Job ETL (`bcb-staging-transform`) |
| `modules/athena` | Workgroup Athena e configurações de query |
| `modules/secrets` | Secrets no AWS Secrets Manager |

## Script do Glue Job

O script `bcb_staging_transform.py` não está neste repositório — pertence ao `bcb-warehouse`
e é mantido em `s3://bcb-warehouse/glue/scripts/bcb_staging_transform.py`.

Para atualizar o script após mudanças no código:

```bash
AWS_PROFILE=bcb-infra-admin aws s3 cp \
  path/to/bcb_staging_transform.py \
  s3://bcb-warehouse/glue/scripts/bcb_staging_transform.py
```

O `terraform apply` não detecta mudanças no conteúdo do script (apenas no path configurado).

## CI/CD

- **PR aberto:** `terraform plan` executado automaticamente, resultado postado no PR
- **Merge em main:** `terraform apply` executado automaticamente (environment: production)
- Autenticação via OIDC — sem credenciais estáticas armazenadas (ver ADR-0004)

## Decisões arquiteturais

Ver `docs/adr/` para o registro completo de decisões.

---

Projeto de portfólio — Lucas de Araújo, Engenheiro de Dados

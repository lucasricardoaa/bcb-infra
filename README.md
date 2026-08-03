# bcb-infra

[![Terraform Apply](https://github.com/lucasricardoaa/bcb-infra/actions/workflows/terraform-apply.yml/badge.svg)](https://github.com/lucasricardoaa/bcb-infra/actions/workflows/terraform-apply.yml)

Infraestrutura como código (Terraform + GitHub Actions CI/CD) para os projetos do portfólio BCB.
Provisiona e gerencia todos os recursos AWS dos Projetos 1 e 2 a partir de um único repositório.

> **Contexto do portfólio:**
> [bcb-pipeline](https://github.com/lucasricardoaa/bcb-pipeline) → [bcb-warehouse](https://github.com/lucasricardoaa/bcb-warehouse) → **bcb-infra** (este)
>
> O bcb-pipeline ingere dados da API do Banco Central e os deposita em S3.
> O bcb-warehouse transforma esses dados em um star schema Iceberg consultável via Athena.
> Este projeto provisiona toda a infraestrutura AWS dos dois projetos e adiciona CI/CD automatizado.

---

## O que este projeto demonstra

| Competência | Como é demonstrada |
|---|---|
| Terraform modular | 6 módulos independentes por serviço AWS: `s3`, `iam`, `glue`, `athena`, `secrets`, `billing` |
| GitHub Actions CI/CD | `terraform plan` automático em PRs com resultado postado; `terraform apply` automático no merge |
| OIDC sem credenciais estáticas | Role IAM assumida via token GitHub Actions — sem `AWS_ACCESS_KEY_ID` armazenada |
| Least privilege IAM | Policies scoped por ARN exato, ações específicas por serviço; GitHub Actions com permissões mínimas |
| State remoto + locking | Backend S3 + tabela DynamoDB para state centralizado e proteção contra writes concorrentes |
| `terraform import` | 15 recursos existentes do bcb-pipeline importados para o state sem recreação |
| Supply chain security | SHA pinning imutável em todas as GitHub Actions + Dependabot com schedule semanal |
| Cost control | AWS Budget de $10/mês com alertas de previsão (80%) e consumo real (100%) |

---

## Arquitetura

```
┌──────────────────────────────────────────────────────────────────┐
│                      bcb-infra (Terraform)                       │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │     S3       │  │     IAM      │  │        Glue          │   │
│  │              │  │              │  │                      │   │
│  │ bcb-pipeline │  │ bcb-pipeline │  │ database bcb_pipeline│   │
│  │   -raw       │  │   -dev (user)│  │ ├── usd_brl          │   │
│  │ bcb-pipeline │  │ bcb-lambda   │  │ ├── selic            │   │
│  │   -staging   │  │   -role      │  │ └── ipca             │   │
│  │ bcb-pipeline │  │ bcb-glue     │  │                      │   │
│  │   -analytics │  │   -role      │  │ database bcb_warehouse│  │
│  │ bcb-warehouse│  │ bcb-github   │  │                      │   │
│  │              │  │   -actions   │  │ job bcb-staging-     │   │
│  │              │  │   -oidc      │  │   transform (PySpark)│   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │    Athena    │  │   Secrets    │  │       Billing        │   │
│  │              │  │   Manager    │  │                      │   │
│  │ workgroup    │  │              │  │ Budget $10/mês        │   │
│  │   bcb-dbt    │  │ dbt/athena   │  │ alertas 80% forecast │   │
│  │              │  │   -config    │  │ e 100% real          │   │
│  │              │  │ airflow/aws  │  │                      │   │
│  │              │  │   -creds     │  │                      │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

### CI/CD

```
PR aberto
  └── terraform-plan.yml
        ├── OIDC auth (sem credenciais estáticas)
        ├── terraform init + validate + fmt check
        ├── terraform plan
        └── resultado postado como comentário no PR

Merge em main
  └── terraform-apply.yml
        ├── OIDC auth
        ├── terraform init + validate
        ├── terraform plan -out=tfplan
        └── terraform apply tfplan
              └── environment: production (rastreável no GitHub Deployments)
```

---

## Stack

| Camada | Tecnologia |
|---|---|
| IaC | Terraform >= 1.9, provider AWS v5 |
| CI/CD | GitHub Actions (SHA-pinned) |
| Autenticação CI/CD | AWS OIDC — sem credenciais estáticas |
| State backend | Amazon S3 + DynamoDB (locking) |
| Cloud | AWS us-east-1: S3, IAM, Glue, Athena, Secrets Manager, Budgets |
| Supply chain | Dependabot (schedule semanal, segundas-feiras) |

---

## Estrutura do repositório

```
bcb-infra/
  terraform/
    modules/
      s3/          # 4 buckets + lifecycle + SSE + versioning + public access block
      iam/         # user bcb-pipeline-dev, roles Lambda/Glue, OIDC provider + role
      glue/        # databases bcb_pipeline e bcb_warehouse, 3 tabelas, Glue Job ETL
      athena/      # workgroup bcb-dbt (enforce=true, 1 GB cutoff, SSE)
      secrets/     # 2 secrets no Secrets Manager (valores gerenciados externamente)
      billing/     # AWS Budget mensal com alertas de custo
    backend.tf               # S3 backend + DynamoDB lock
    providers.tf             # provider AWS, required_version
    variables.tf             # variáveis globais
    main.tf                  # orquestrador — chama os módulos
    outputs.tf               # ARNs e nomes de recursos
    terraform.tfvars.example # template de variáveis (terraform.tfvars não versionado)
  .github/
    workflows/
      terraform-plan.yml     # dispara em pull_request → main
      terraform-apply.yml    # dispara em push → main
    dependabot.yml           # atualização automática de action SHAs
  scripts/
    bootstrap-backend.sh     # cria o bucket S3 e tabela DynamoDB do backend
  docs/
    adr/                     # 6 ADRs com todas as decisões arquiteturais
    architecture/
```

---

## Decisões arquiteturais

Todas as decisões estruturais estão documentadas em [`docs/adr/`](docs/adr/):

| ADR | Decisão |
|---|---|
| [0001](docs/adr/0001-backend-remoto-terraform.md) | Backend remoto: S3 + DynamoDB para state centralizado e locking |
| [0002](docs/adr/0002-organizacao-modulos-terraform.md) | Módulos por serviço AWS — um módulo por responsabilidade |
| [0003](docs/adr/0003-escopo-bcb-infra.md) | Escopo: provisionamento + CI/CD para os 3 projetos do portfólio |
| [0004](docs/adr/0004-autenticacao-github-actions-oidc.md) | Autenticação GitHub Actions via OIDC — sem credenciais estáticas |
| [0005](docs/adr/0005-bootstrap-backend.md) | Bootstrap manual do backend (problema chicken-and-egg do Terraform) |
| [0006](docs/adr/0006-gestao-secrets-terraform.md) | Terraform cria os secrets; valores preenchidos fora do Terraform |

---

## Como usar

### 1. Bootstrap do backend (uma única vez)

Antes do primeiro `terraform init`, o bucket S3 e a tabela DynamoDB precisam existir:

```bash
bash scripts/bootstrap-backend.sh
```

### 2. Configurar variáveis

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Preencher os valores: aws_account_id, github_org, github_user_id,
# github_repo_infra_id e alert_email
```

### 3. Init, Plan e Apply

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

### 4. Configurar o repositório GitHub para CI/CD

Após o apply, configure no GitHub Settings do repositório:

| Configuração | Valor |
|---|---|
| Variable `AWS_ACCOUNT_ID` | ID da conta AWS |
| Variable `GH_ORG` | usuário/org GitHub |
| Variable `GH_USER_ID` | ID numérico do usuário (`gh api user --jq '.id'`) |
| Variable `GH_REPO_INFRA_ID` | ID numérico do repo (`gh api repos/OWNER/bcb-infra --jq '.id'`) |
| Variable `ALERT_EMAIL` | email para alertas de custo |

---

## Notas operacionais

- **`terraform.tfvars` não é versionado.** Contém valores reais de conta AWS e email. O arquivo `.example` documenta todas as variáveis necessárias.

- **Script do Glue Job não está neste repositório.** O script `bcb_staging_transform.py` pertence ao bcb-warehouse e é mantido em `s3://bcb-warehouse/glue/scripts/`. O Terraform gerencia apenas o Job e seu path — não detecta mudanças no conteúdo do script.

- **Secrets Manager com valores externos.** O Terraform cria os dois secrets com `ignore_changes = [secret_string]`. Os valores reais (`bcb/dbt/athena-config` e `bcb/airflow/aws-credentials`) são preenchidos manualmente ou pelo pipeline de cada projeto.

- **OIDC trust policy com IDs numéricos.** O GitHub incluiu IDs numéricos no `sub` claim a partir de 2025 (`repo:ORG@USER_ID/REPO@REPO_ID:*`). As variáveis `github_user_id` e `github_repo_infra_id` são necessárias para o formato correto.

---

Projeto de portfólio — Lucas de Araújo, Engenheiro de Dados

# ADR-0001: Backend remoto Terraform com S3 e DynamoDB

## Status
Aceito

## Contexto
O Terraform precisa armazenar o state file de forma persistente e acessível pelo
pipeline de CI/CD. A alternativa padrão — state local — impede execução em GitHub
Actions e não oferece controle de concorrência. É necessário escolher um backend que
suporte lock de state, seja reproduzível e não introduza dependências externas desnecessárias.

## Decisão
Usar S3 como storage do state file com DynamoDB para lock de estado (mecanismo
nativo do provider AWS do Terraform). O bucket e a tabela são criados via script
AWS CLI antes do primeiro `terraform init` (ver ADR-0005).

Configuração:
- Bucket: `bcb-infra-terraform-state`
- Key: `bcb-infra/terraform.tfstate`
- Região: `us-east-1`
- DynamoDB table: `bcb-infra-terraform-locks`
- Criptografia em repouso: `encrypt = true`

## Consequências

### Positivas
- Sem custo adicional relevante — S3 e DynamoDB já fazem parte da conta AWS do portfólio
- Suporte nativo a lock de state, evitando conflitos em execuções paralelas
- State versionado via versionamento do bucket S3
- Sem dependência de serviço externo à conta AWS

### Negativas / Trade-offs
- O bucket e a tabela precisam existir antes do `terraform init` — problema do ovo e da galinha
  mitigado pelo script de bootstrap (ADR-0005)
- O state pode conter valores sensíveis — mitigado por `encrypt = true` e política de acesso restrita ao bucket

## Alternativas consideradas
- **Terraform Cloud**: oferece backend gerenciado com UI e controle de acesso — rejeitado por
  introduzir dependência de serviço externo desnecessário para um portfólio já hospedado na AWS
- **State local**: simples de configurar — rejeitado por não suportar CI/CD (o state não é
  compartilhado entre runners do GitHub Actions) e por ausência de lock de concorrência

## Relação com outras ADRs
- ADR-0005: define como o bucket e a tabela DynamoDB são criados antes do primeiro `terraform init`

## Revisão
Elaborado por: Claude (Agente IA) — arquiteto-dados-aws
Data/hora: 2026-07-23 00:35 BRT

## Aprovação
Aprovado por: Lucas de Araújo
Data/hora: 2026-07-23 01:01 BRT

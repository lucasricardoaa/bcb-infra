# ADR-0003: Escopo do bcb-infra — o que é e o que não é gerenciado

## Status
Aceito

## Contexto
O bcb-infra provisiona infraestrutura para dois projetos. O bcb-pipeline já opera
na AWS com recursos existentes (S3, IAM, Glue, Lambda, ECR). É necessário definir
quais recursos entram no escopo do bcb-infra para evitar acoplamento indevido com
dependências que o bcb-infra não controla.

O ponto crítico é a Lambda `bcb-raw-to-staging`: ela pertence ao bcb-pipeline e
depende de uma imagem Docker publicada no ECR pelo pipeline de CI/CD do bcb-pipeline.
Se o bcb-infra gerenciasse a Lambda, um `terraform apply` do bcb-infra poderia tentar
recriar a Lambda em um momento em que a imagem no ECR não está disponível.

## Decisão
**Fora do escopo do bcb-infra:**
- Lambda `bcb-raw-to-staging` (pertence ao bcb-pipeline; tem dependência de imagem ECR)
- Repositório ECR da imagem da Lambda (gerenciado pelo bcb-pipeline)
- Qualquer recurso cujo ciclo de vida é acoplado a um artefato de build externo

**Dentro do escopo do bcb-infra:**
- Buckets S3: raw, staging, analytics (importados do bcb-pipeline) e warehouse (novo)
- IAM roles: Glue crawler, OIDC GitHub Actions
- Glue Data Catalog: databases e crawlers
- Athena: workgroup
- Secrets Manager: secrets do projeto

O bcb-infra **importa** os recursos existentes do bcb-pipeline para o seu state.
O propósito é ter visibilidade e controle de drift, não recriar esses recursos.

## Consequências

### Positivas
- Ausência de dependências circulares entre o bcb-infra e o bcb-pipeline
- `terraform destroy` no bcb-infra não afeta a Lambda em operação
- Responsabilidades claras: bcb-pipeline é dono da Lambda; bcb-infra é dono da infraestrutura de dados

### Negativas / Trade-offs
- A Lambda fica fora do controle de Terraform — drift de configuração não é detectado automaticamente
- Dois repositórios precisam ser atualizados se a arquitetura da Lambda mudar
  (bcb-pipeline para o código, bcb-infra para recursos relacionados como IAM policies)

## Alternativas consideradas
- **Importar a Lambda para o bcb-infra**: consolidaria todos os recursos em um único state —
  rejeitado porque `terraform apply` passaria a depender da disponibilidade da imagem ECR,
  criando uma dependência que o bcb-infra não controla e que pode causar falha em apply
- **Criar um módulo lambda separado com `lifecycle.prevent_destroy`**: reduziria o risco de
  destruição acidental mas não resolve o problema da dependência da imagem ECR no momento
  do `terraform apply` — rejeitado pela mesma razão

## Revisão
Elaborado por: Claude (Agente IA) — arquiteto-dados-aws
Data/hora: 2026-07-23 00:45 BRT

## Aprovação
Aprovado por: Lucas de Araújo
Data/hora: 2026-07-23 01:01 BRT

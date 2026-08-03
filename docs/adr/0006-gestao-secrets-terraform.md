# ADR-0006: Gestão de secrets no Terraform com Secrets Manager

## Status
Aceito

## Contexto
O bcb-pipeline e o bcb-warehouse precisam de um mecanismo padronizado para recuperar
credenciais em runtime (ex: tokens de API, senhas de banco). O Terraform gerencia o
ciclo de vida dos recursos AWS, mas também tem acesso ao state file — que pode ser
lido por qualquer pessoa com acesso ao bucket S3 do backend.

É necessário decidir como o Terraform interage com segredos: se os cria com valores
reais (risco de exposição no state), se os ignora completamente (perde visibilidade
sobre a existência do recurso) ou se adota uma abordagem intermediária.

## Decisão
O Terraform gerencia a **existência e as permissões** dos secrets no AWS Secrets Manager,
mas não o seu **valor**. Os recursos `aws_secretsmanager_secret` são criados com
`secret_string = "{}"` (objeto JSON vazio). Após o `terraform apply`, o engenheiro
responsável preenche o valor real manualmente via AWS CLI ou console.

Essa abordagem garante que:
- O Terraform controla permissões de acesso (via IAM policies no módulo `iam/`)
- O caminho do secret é padronizado e rastreável no código
- Nenhum valor sensível toca o state file, o código-fonte ou o pipeline de CI/CD

### Origem dos valores

| Secret | Conteúdo | Origem |
|---|---|---|
| `bcb/airflow/aws-credentials` | `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` do IAM user `bcb-pipeline-dev` | Gerados via IAM Console. Em caso de perda, revogar e gerar novo par de chaves — sem necessidade de backup do valor. |
| `bcb/dbt/athena-config` | Workgroup (`bcb-dbt`), região (`us-east-1`), output location (`s3://bcb-warehouse/athena-results/`) | Configurações definidas no próprio bcb-infra (ADR-0001, módulo `athena`). Recuperáveis a partir do código. |

## Consequências

### Positivas
- Valores sensíveis nunca aparecem no state file, no git history ou nos logs do CI/CD
- As aplicações têm um caminho de secret estável e padronizado para recuperar credenciais
- Permissões de acesso ao secret são gerenciadas junto com os demais recursos IAM
- Separação clara entre infraestrutura (Terraform) e dados sensíveis (preenchimento manual)

### Negativas / Trade-offs
- Após cada `terraform apply`, um passo manual é necessário para preencher os valores —
  documentado no README e em runbooks de operação
- Se o secret for destruído e recriado (ex: `terraform destroy && apply`), o valor é
  perdido e precisa ser reconfigurado manualmente

## Alternativas consideradas
- **Secrets hardcoded em `terraform.tfvars`**: simples de implementar — rejeitado porque
  `terraform.tfvars` pode ser acidentalmente versionado e o valor fica no state file
- **Valores reais no state via `sensitive = true`**: o Terraform mascara a saída mas o
  state file armazena o valor em texto claro — rejeitado porque o state é armazenado
  no S3 e acessível a qualquer pessoa com permissão de leitura no bucket
- **Sem Secrets Manager (variáveis de ambiente nas aplicações)**: evita o custo do
  Secrets Manager — rejeitado porque não há mecanismo centralizado de rotação e auditoria,
  e as aplicações já existentes no bcb-pipeline usam Secrets Manager

## Revisão
Elaborado por: Claude (Agente IA) — arquiteto-dados-aws
Data/hora: 2026-07-23 01:00 BRT

## Aprovação
Aprovado por: Lucas de Araújo
Data/hora: 2026-07-23 01:01 BRT

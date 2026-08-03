# ADR-0002: Organização de módulos Terraform por serviço AWS

## Status
Aceito

## Contexto
O bcb-infra gerencia recursos de dois projetos distintos (bcb-pipeline e bcb-warehouse)
que compartilham serviços AWS como S3, IAM e Glue. É necessário definir como organizar
os módulos Terraform para evitar duplicação, facilitar o import de recursos existentes
e permitir que as fases de implementação sejam executadas de forma independente.

## Decisão
Organizar os módulos por serviço AWS, não por projeto de negócio:

```
terraform/modules/
  s3/       — todos os buckets (raw, staging, analytics, warehouse)
  iam/      — todas as roles e políticas (Glue, Athena, OIDC)
  glue/     — todos os databases e crawlers do Data Catalog
  athena/   — workgroup e configurações de query
  secrets/  — todos os secrets no Secrets Manager
```

Cada módulo recebe `project_prefix` e `environment` como variáveis de entrada,
garantindo nomenclatura consistente entre recursos de projetos diferentes.

## Consequências

### Positivas
- Recursos compartilhados (ex: bucket S3 acessado por Glue e Lambda) residem em um
  único módulo, eliminando duplicação de definição
- Import de recursos existentes é agrupado por serviço — facilita execução em fases
- Módulos menores e com responsabilidade única são mais fáceis de testar e auditar
- Expansão futura (ex: novo projeto bcb-X) reusa os mesmos módulos com novos prefixos ou recursos

### Negativas / Trade-offs
- A separação por serviço pode obscurecer quais recursos pertencem a qual projeto —
  mitigado por comentários explícitos nos arquivos `main.tf` de cada módulo
- Um `terraform destroy` afeta recursos de ambos os projetos simultaneamente —
  aceitável pois o bcb-infra é o único responsável por esses recursos

## Alternativas consideradas
- **Módulos por projeto (bcb-pipeline / bcb-warehouse)**: intuitivo para entender a
  origem dos recursos, mas força duplicação de recursos compartilhados (ex: IAM roles
  usadas por ambos os projetos precisariam ser definidas nos dois módulos ou em um terceiro
  módulo de dependência) — rejeitado por aumentar complexidade e acoplamento
- **Estrutura flat (sem módulos)**: todos os recursos em `main.tf` — rejeitado por não
  escalar à medida que o número de recursos cresce e por dificultar o reuso

## Revisão
Elaborado por: Claude (Agente IA) — arquiteto-dados-aws
Data/hora: 2026-07-23 00:40 BRT

## Aprovação
Aprovado por: Lucas de Araújo
Data/hora: 2026-07-23 01:01 BRT

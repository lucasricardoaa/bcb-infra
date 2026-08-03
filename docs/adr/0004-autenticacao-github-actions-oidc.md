# ADR-0004: Autenticação GitHub Actions → AWS via OIDC

## Status
Aceito

## Contexto
O pipeline de CI/CD (GitHub Actions) precisa de permissões na AWS para executar
`terraform plan` e `terraform apply`. A solução mais comum — IAM user com access key
armazenada como GitHub Secret — cria credenciais de longa duração que precisam ser
rotacionadas manualmente e, se vazadas, concedem acesso permanente à conta AWS.

Esta ADR trata especificamente da autenticação GitHub Actions → AWS para o repositório
bcb-infra. A adoção do GitHub Actions como plataforma de CI/CD para todos os
repositórios do portfólio é declarada na seção Escopo do padrão abaixo.

## Decisão
Usar autenticação via OIDC (OpenID Connect) com uma role IAM dedicada
(`bcb-github-actions-oidc`). O GitHub é configurado como Identity Provider na conta
AWS. O GitHub Actions assume a role temporariamente por sessão, sem nenhuma credencial
estática armazenada.

A trust policy da role restringe o acesso ao repositório `bcb-infra` da organização
configurada em `var.github_org`, evitando que outros repositórios do mesmo GitHub org
possam assumir a role.

Fluxo de autenticação:
1. GitHub Actions solicita token OIDC ao GitHub
2. `aws-actions/configure-aws-credentials` apresenta o token à AWS
3. AWS valida o token contra o Identity Provider do GitHub
4. AWS emite credenciais temporárias (STS AssumeRoleWithWebIdentity)
5. Credenciais expiram ao fim do job

## Escopo do padrão — GitHub Actions como plataforma de CI/CD do portfólio

GitHub Actions é a plataforma de CI/CD adotada para todos os repositórios do portfólio,
não apenas para o bcb-infra. A escolha é uniforme e se aplica a projetos atuais e futuros.

Repositórios cobertos:

| Repositório | Tipo de workflow |
|---|---|
| `bcb-pipeline` | Qualidade de código: ruff, mypy, pytest (testes unitários com moto) |
| `bcb-warehouse` | Qualidade de código: ruff, mypy, pytest (testes PySpark), dbt parse |
| `bcb-infra` | Infraestrutura: terraform plan / apply com autenticação OIDC (esta ADR) |
| Futuros repositórios do portfólio | GitHub Actions por padrão, salvo decisão explícita em contrário |

Os workflows se dividem em duas categorias distintas:

**Workflows de qualidade de código** (bcb-pipeline, bcb-warehouse): executam lint,
verificação de tipos e testes unitários. Não interagem com a AWS — dependências AWS são
mockadas (moto, pytest fixtures locais). Não requerem autenticação OIDC nem credenciais.

**Workflows de infraestrutura** (bcb-infra): executam `terraform plan` e `terraform apply`
com autenticação OIDC para a conta AWS. O mecanismo de autenticação é o tema central desta
ADR e se aplica exclusivamente a este repositório.

A separação é intencional: repositórios de dados não devem ter acesso à conta AWS via
CI/CD — isso é responsabilidade exclusiva do bcb-infra, conforme ADR-0003 (escopo).

## Consequências

### Positivas
- Sem credenciais estáticas no GitHub Secrets — elimina o risco de vazamento de access keys
- Credenciais geradas por sessão com escopo restrito ao repositório e branch configurados
- Rotação automática — nenhuma tarefa operacional de rotação de credenciais
- Prática recomendada pela AWS e pelo GitHub para integração com provedores de nuvem

### Negativas / Trade-offs
- Requer configuração inicial do OIDC provider na conta AWS — recurso gerenciado pelo
  próprio bcb-infra (problema de bootstrap análogo ao do backend)
- A role IAM e o OIDC provider precisam existir antes do primeiro apply via CI/CD;
  o apply inicial deve ser executado localmente com credenciais de administrador

## Alternativas consideradas
- **IAM user com access key como GitHub Secret**: simples de configurar — rejeitado por
  criar credenciais de longa duração que precisam de rotação manual e que, se expostas,
  concedem acesso contínuo à conta AWS até serem revogadas

## Revisão
Elaborado por: Claude (Agente IA) — arquiteto-dados-aws
Data/hora: 2026-07-23 00:50 BRT

## Aprovação
Aprovado por: Lucas de Araújo
Data/hora: 2026-07-23 01:01 BRT

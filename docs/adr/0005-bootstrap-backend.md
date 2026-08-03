# ADR-0005: Bootstrap do backend Terraform via script AWS CLI

## Status
Aceito

## Contexto
O backend remoto do Terraform (S3 + DynamoDB, definido em ADR-0001) precisa existir
antes que `terraform init` possa ser executado. Este é o problema clássico do ovo e
da galinha em Terraform: não é possível usar o Terraform para criar o próprio backend
antes de inicializá-lo.

É necessário escolher um mecanismo para criar esses recursos bootstrapping de forma
reproduzível, documentada e sem dependência de acesso manual ao console AWS.

## Decisão
Criar um script bash (`scripts/bootstrap-backend.sh`) que usa a AWS CLI para:
1. Criar o bucket `bcb-infra-terraform-state` com versionamento habilitado e
   bloqueio de acesso público ativado
2. Criar a tabela DynamoDB `bcb-infra-terraform-locks` com `LockID` como partition key
   e billing mode `PAY_PER_REQUEST`

O script é executado manualmente **uma única vez** pelo engenheiro responsável,
antes do primeiro `terraform init`. Após o bootstrap, os recursos são gerenciados
exclusivamente via AWS CLI e console — não são importados para o state do Terraform
(importá-los criaria dependência circular).

## Consequências

### Positivas
- Script rastreável no repositório — qualquer membro da equipe pode executar o bootstrap
  em uma nova conta seguindo o mesmo procedimento
- Simples de auditar: apenas dois recursos, duas chamadas AWS CLI
- Sem dependência de conta Terraform Cloud ou de ferramentas além da AWS CLI

### Negativas / Trade-offs
- Os recursos de bootstrap (bucket e tabela DynamoDB) ficam fora do state do Terraform —
  drift de configuração não é detectado automaticamente
- Requer execução manual com credenciais de administrador — não é automatizado no CI/CD
  (intencional: bootstrap é uma operação pontual, não recorrente)

## Alternativas consideradas
- **Módulo Terraform separado para o backend**: o módulo bootstrap seria inicializado com
  state local e depois o state seria migrado — rejeitado por adicionar complexidade
  operacional desnecessária para um portfólio com um único ambiente
- **Criação manual via console AWS**: funcionaria, mas não é rastreável no repositório
  e depende de memória ou documentação externa — rejeitado por ser menos reproduzível

## Relação com outras ADRs
- ADR-0001: define os parâmetros do backend que este script cria

## Revisão
Elaborado por: Claude (Agente IA) — arquiteto-dados-aws
Data/hora: 2026-07-23 00:55 BRT

## Aprovação
Aprovado por: Lucas de Araújo
Data/hora: 2026-07-23 01:01 BRT

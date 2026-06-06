# SDD — Sessão 18: Deploy da Infraestrutura AWS

## 1. Contexto e Problema

O ContratoIA possui todo o Terraform escrito (sessão 13) com módulos para VPC, EC2, S3, SQS, Secrets Manager e CloudWatch, mas nunca foi aplicado em uma conta AWS real. Não existe infraestrutura rodando — tudo é local (Docker Compose).

Para que o backend funcione em produção, precisamos criar uma conta AWS, configurar credenciais, habilitar o backend S3 para state remoto, e executar `terraform apply` para provisionar toda a infra.

Sem essa sessão, o projeto continua sendo apenas código — não há ambiente real acessível pela internet.

## 2. Escopo da Correção

### O que muda

| Componente | Mudança |
|---|---|
| Conta AWS | Criar conta, configurar IAM user para Terraform |
| Backend S3 | Criar bucket + DynamoDB table para state remoto (manual, antes do Terraform) |
| `environments/production/main.tf` | Descomentar bloco `backend "s3"` |
| `environments/staging/main.tf` | Descomentar bloco `backend "s3"` |
| Security Groups | Validar e ajustar CIDRs de SSH com IP real |
| Terraform state | Migrar de local para S3 |

### O que NÃO muda

- Módulos Terraform existentes — zero alterações no código
- Código do backend/frontend — nenhuma mudança
- Cloudflare (sessão 17) — independente
- Docker Compose local — continua funcionando para dev

## 3. Design da Solução

### 3.1 Pré-requisitos manuais (usuário)

1. Criar conta AWS (se não tem)
2. Criar IAM user `terraform-deployer` com `AdministratorAccess` (inicial, refinar depois)
3. Gerar Access Key + Secret Key
4. Criar manualmente o bucket S3 `contrato-ia-terraform-state` e DynamoDB table `contrato-ia-terraform-locks`
5. Configurar AWS CLI: `aws configure`

### 3.2 Habilitar backend remoto

Descomentar os blocos `backend "s3"` em `production/main.tf` e `staging/main.tf`.

### 3.3 Primeiro apply

```bash
cd environments/production
terraform init
terraform plan -out=plan.tfplan
# Revisar o plan
terraform apply plan.tfplan
```

### 3.4 Outputs esperados

Após o apply, teremos:
- VPC com 4 subnets (2 públicas, 2 privadas) em `sa-east-1`
- EC2 `t3.small` com Elastic IP e Docker instalado
- S3 bucket para documentos
- SQS FIFO queue + DLQ
- Secrets Manager com credenciais
- CloudWatch Log Group

## 4. Fluxo após a correção

```
Developer laptop                    AWS sa-east-1
─────────────────                   ─────────────────────────────────
terraform apply ──────────────────► VPC (10.0.0.0/16)
                                    ├── Public Subnet A (EC2)
                                    │   └── EC2 t3.small + EIP
                                    │       ├── Docker: backend:8080
                                    │       └── Docker: postgres:5432
                                    ├── Public Subnet B (spare)
                                    ├── Private Subnet A (RDS futuro)
                                    ├── Private Subnet B (RDS futuro)
                                    ├── S3: contrato-ia-documents
                                    ├── SQS: contrato-ia-generation.fifo
                                    ├── Secrets Manager
                                    └── CloudWatch Logs
```

## 5. Arquivos a modificar/criar

| Arquivo | Tipo | Descrição |
|---|---|---|
| `environments/production/main.tf` | MODIFICAR | Descomentar backend S3 |
| `environments/staging/main.tf` | MODIFICAR | Descomentar backend S3 |
| `environments/production/terraform.tfvars` | MODIFICAR | Adicionar `ssh_allowed_cidrs` com IP real |
| `CLAUDE.md` | MODIFICAR | Documentar credenciais AWS e processo de apply |

## 6. Critérios de Aceite

- [ ] Conta AWS criada e configurada
- [ ] IAM user com credenciais funcionando (`aws sts get-caller-identity`)
- [ ] Backend S3 para Terraform state criado e funcional
- [ ] `terraform init` com backend remoto passa sem erros
- [ ] `terraform plan` mostra todos os recursos esperados
- [ ] `terraform apply` completa sem erros
- [ ] EC2 acessível via SSH (Elastic IP)
- [ ] Security groups configurados corretamente
- [ ] Todos os outputs disponíveis (IP, bucket name, queue URL)

## 7. Considerações adicionais

### Custo
- EC2 t3.small: ~$15/mês
- S3 + SQS + Secrets + CloudWatch: ~$1/mês
- **Total: ~$16/mês**

### Segurança
- IAM user inicial com `AdministratorAccess` — refinar para least privilege depois do primeiro apply
- SSH restrito ao IP do desenvolvedor
- Habilitar MFA na conta root AWS
- Nunca commitar Access Keys no git

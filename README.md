# ContratoIA - Infraestrutura (Terraform)

Infraestrutura AWS para a plataforma ContratoIA, gerenciada via Terraform.

## Arquitetura

```
┌──────────────────────────────────────────────────────────────┐
│                         VPC (sa-east-1)                       │
│                                                               │
│  ┌─────────────────────────┐  ┌─────────────────────────────┐ │
│  │   Public Subnet (AZ-a)  │  │   Public Subnet (AZ-b)      │ │
│  │                         │  │                              │ │
│  │  ┌───────────────────┐  │  │                              │ │
│  │  │  EC2 (t3.small)   │  │  │                              │ │
│  │  │  Docker + Backend  │  │  │                              │ │
│  │  │  CloudWatch Agent  │  │  │                              │ │
│  │  └───────────────────┘  │  │                              │ │
│  └─────────────────────────┘  └─────────────────────────────┘ │
│                                                               │
│  ┌─────────────────────────┐  ┌─────────────────────────────┐ │
│  │  Private Subnet (AZ-a)  │  │  Private Subnet (AZ-b)      │ │
│  │                         │  │                              │ │
│  │  ┌───────────────────┐  │  │                              │ │
│  │  │  RDS PostgreSQL   │  │  │                              │ │
│  │  │  (db.t3.micro)    │  │  │                              │ │
│  │  └───────────────────┘  │  │                              │ │
│  └─────────────────────────┘  └─────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘

           ┌──────────┐    ┌──────────┐    ┌──────────────────┐
           │   S3     │    │ SQS FIFO │    │ Secrets Manager  │
           │  (docs)  │    │  + DLQ   │    │  (credentials)   │
           └──────────┘    └──────────┘    └──────────────────┘

           ┌──────────────────────────────────────────────────┐
           │              CloudWatch Logs + Metrics            │
           └──────────────────────────────────────────────────┘
```

## Custo estimado (~$23/mes em producao)

| Recurso | Tipo | Custo/mes |
|---------|------|-----------|
| EC2 | t3.small (2 vCPU, 2GB RAM) | ~$15 |
| RDS PostgreSQL | db.t3.micro (free tier eligible) | ~$7 |
| S3 | Standard (poucos GB) | ~$0 |
| SQS FIFO | Baixo volume | ~$0 |
| CloudWatch | Logs + metricas basicas | ~$0.50 |
| Secrets Manager | 1 secret | ~$0.40 |
| Elastic IP | Vinculado a EC2 | $0 |
| **Total** | | **~$23** |

## Pre-requisitos

- **Terraform** >= 1.5
- **AWS CLI** configurado com credenciais
- **Conta AWS** com permissoes para criar recursos

## Como usar

### 1. Configurar credenciais AWS

```bash
aws configure
# Ou exporte diretamente:
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

### 2. Configurar variaveis sensiveis

```bash
# NUNCA commite esses valores no git!
export TF_VAR_db_password="senha-forte-aqui"
export TF_VAR_claude_api_key="sk-ant-sua-chave"
```

### 3. Inicializar e aplicar

```bash
cd environments/production   # ou staging

terraform init
terraform plan               # Sempre revise o plan antes!
terraform apply
```

### 4. Obter outputs

```bash
terraform output backend_public_ip
terraform output database_endpoint
terraform output s3_bucket_name
terraform output sqs_generation_queue_url
```

## Estrutura do projeto

```
contrato-ia-infra/
├── environments/
│   ├── staging/          # Ambiente de homologacao
│   │   ├── main.tf       # Composicao dos modulos
│   │   ├── variables.tf  # Variaveis do ambiente
│   │   ├── outputs.tf    # Outputs
│   │   └── terraform.tfvars  # Valores nao-sensiveis
│   └── production/       # Ambiente de producao
│       └── (mesma estrutura)
├── modules/
│   ├── networking/       # VPC, subnets, security groups
│   ├── compute/          # EC2, IAM, CloudWatch
│   ├── database/         # RDS PostgreSQL
│   ├── storage/          # S3 bucket
│   ├── queue/            # SQS FIFO + DLQ
│   └── secrets/          # Secrets Manager
├── scripts/
│   └── user-data.sh      # Bootstrap da EC2 (Docker + CloudWatch)
└── .github/workflows/
    └── terraform.yml     # CI/CD: plan em PR, apply manual
```

## CI/CD

| Trigger | Acao |
|---------|------|
| PR para `main` | `terraform plan` automatico |
| Push em `main` | `terraform plan` automatico |
| Manual (workflow_dispatch) | Plan ou Apply no ambiente escolhido |

**Apply e sempre manual** — nunca aplica automaticamente.

Para aplicar:
1. Va em **Actions** → **Terraform** → **Run workflow**
2. Escolha o environment (`staging` ou `production`)
3. Escolha a action (`plan` primeiro, depois `apply`)

## Deploy do backend na EC2

Apos o `terraform apply`, a EC2 ja esta pronta com Docker. Para deployar:

```bash
# SSH na EC2
ssh -i sua-chave.pem ec2-user@<ELASTIC_IP>

# Deploy manual (usando o script criado pelo user-data)
export GHCR_TOKEN="seu-github-token"
export GHCR_USER="seu-github-user"
/opt/contrato-ia/deploy.sh ghcr.io/jokerfoxyy/contrato-ia-backend:latest
```

O script `deploy.sh`:
1. Faz login no GHCR
2. Puxa a imagem Docker mais recente
3. Busca credenciais no Secrets Manager
4. Inicia o container com as env vars

## Seguranca

- **RDS** so acessivel pela EC2 (security group restrito)
- **EC2** usa IMDSv2 obrigatorio
- **S3** sem acesso publico, criptografia SSE-S3
- **Secrets** no AWS Secrets Manager (nunca em .tfvars)
- **SSH** restrito a CIDRs especificos
- **EBS** criptografado
- **State remoto** (quando habilitado): S3 + DynamoDB com criptografia

## Migracao futura para ECS

A arquitetura foi desenhada para facilitar migracao:
1. EC2 ja roda Docker — basta trocar por ECS task definition
2. IAM role ja tem as permissoes necessarias
3. Security groups ja separados (EC2/RDS)
4. Secrets Manager ja integrado
5. CloudWatch Logs ja configurado

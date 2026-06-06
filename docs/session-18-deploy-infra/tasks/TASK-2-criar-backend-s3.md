# TASK-2 — Criar backend S3 para Terraform state

## Referência SDD
Seção 3.2 — Habilitar backend remoto

## Dependências
TASK-1 (conta AWS + credenciais)

## Contexto
O Terraform state precisa ser armazenado remotamente para permitir trabalho em equipe e evitar perda de state. O backend S3 + DynamoDB é o padrão da indústria.

Esses recursos são criados MANUALMENTE (chicken-and-egg — o Terraform não pode criar seu próprio backend).

## O que fazer

### 1. Criar bucket S3 (via CLI)
```bash
aws s3api create-bucket \
  --bucket contrato-ia-terraform-state \
  --region sa-east-1 \
  --create-bucket-configuration LocationConstraint=sa-east-1

aws s3api put-bucket-versioning \
  --bucket contrato-ia-terraform-state \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket contrato-ia-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

aws s3api put-public-access-block \
  --bucket contrato-ia-terraform-state \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'
```

### 2. Criar DynamoDB table para locks
```bash
aws dynamodb create-table \
  --table-name contrato-ia-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region sa-east-1
```

### 3. Descomentar backend nos environments
Em `environments/production/main.tf` e `environments/staging/main.tf`, descomentar:
```hcl
backend "s3" {
  bucket         = "contrato-ia-terraform-state"
  key            = "production/terraform.tfstate"  # ou staging/
  region         = "sa-east-1"
  dynamodb_table = "contrato-ia-terraform-locks"
  encrypt        = true
}
```

### 4. Inicializar com backend remoto
```bash
cd environments/production
terraform init
# Se já tinha state local, aceitar migração: yes
```

## Critério de aceite
- [ ] Bucket S3 criado com versionamento e encryption
- [ ] Public access bloqueado no bucket
- [ ] DynamoDB table criada
- [ ] Backend descomentado nos main.tf
- [ ] `terraform init` com backend remoto passa sem erros

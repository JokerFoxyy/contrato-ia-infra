# TASK-1 — Criar conta AWS e configurar credenciais

## Referência SDD
Seção 3.1 — Pré-requisitos manuais

## Dependências
Nenhuma — task independente. Executada PELO USUÁRIO.

## Contexto
O Terraform precisa de credenciais AWS para provisionar recursos. Sem conta AWS, nada pode ser criado.

## O que fazer

### 1. Criar conta AWS
- Acessar [https://aws.amazon.com](https://aws.amazon.com) → "Create an AWS Account"
- Usar e-mail pessoal/empresa
- Cadastrar cartão de crédito (obrigatório, mas Free Tier cobre muita coisa)
- Escolher plano "Basic Support" (grátis)

### 2. Habilitar MFA na conta root
- IAM → Security credentials → MFA → Assign MFA device
- Usar app autenticador (Google Authenticator, Authy, etc.)

### 3. Criar IAM user para Terraform
- IAM → Users → Create user
- Nome: `terraform-deployer`
- Attach policy: `AdministratorAccess` (temporário — refinar depois)
- Sem acesso ao console (só programático)

### 4. Gerar Access Key
- IAM → Users → `terraform-deployer` → Security credentials
- Create access key → "Command Line Interface (CLI)"
- **ANOTAR** Access Key ID + Secret Access Key

### 5. Configurar AWS CLI
```bash
aws configure
# AWS Access Key ID: AKIAXXXXXXXXXXXXXXXXX
# AWS Secret Access Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Default region: sa-east-1
# Default output format: json
```

### 6. Verificar
```bash
aws sts get-caller-identity
# Deve retornar: Account, Arn, UserId
```

## Critério de aceite
- [ ] Conta AWS ativa
- [ ] MFA habilitado na conta root
- [ ] IAM user `terraform-deployer` criado
- [ ] `aws sts get-caller-identity` retorna dados válidos
- [ ] Região padrão: `sa-east-1`

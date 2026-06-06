# TASK-3 — Executar terraform apply (provisionar infraestrutura)

## Referência SDD
Seção 3.3 — Primeiro apply

## Dependências
TASK-1 + TASK-2

## Contexto
Com credenciais e backend prontos, executar o apply para criar toda a infraestrutura AWS.

## O que fazer

### 1. Configurar variáveis sensíveis
```bash
export TF_VAR_db_password="gerar-senha-forte-aqui"
export TF_VAR_claude_api_key="sk-ant-sua-chave"
export TF_VAR_cloudflare_api_token="token-da-sessao-17"
export TF_VAR_cloudflare_zone_id="zone-id-da-sessao-17"
```

### 2. Atualizar ssh_allowed_cidrs
Descobrir seu IP público:
```bash
curl ifconfig.me
```
Editar `terraform.tfvars`:
```hcl
ssh_allowed_cidrs = ["SEU_IP/32"]
```

### 3. Plan + Apply
```bash
cd environments/production
terraform plan -out=plan.tfplan
# REVISAR o plan cuidadosamente
terraform apply plan.tfplan
```

### 4. Anotar outputs
```bash
terraform output
# backend_public_ip = "x.x.x.x"
# s3_bucket_name = "contrato-ia-production-documents"
# sqs_generation_queue_url = "https://sqs.sa-east-1.amazonaws.com/..."
```

### 5. Testar acesso SSH
```bash
ssh -i sua-chave.pem ec2-user@<backend_public_ip>
```

## Critério de aceite
- [ ] `terraform apply` completa sem erros
- [ ] EC2 rodando e acessível via SSH
- [ ] Elastic IP atribuído
- [ ] S3 bucket criado
- [ ] SQS queues criadas
- [ ] Secrets Manager com credenciais
- [ ] CloudWatch Log Group criado

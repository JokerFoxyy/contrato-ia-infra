# IAM Setup para Terraform CI

## Passo a passo no AWS Console

### 1. Criar a Policy

1. Va em **IAM** → **Policies** → **Create policy**
2. Clique na aba **JSON**
3. Cole o conteudo de `terraform-ci-policy.json`
4. Nome: `ContratoIA-Terraform-CI`
5. Descricao: `Permissoes minimas para o Terraform gerenciar a infra do ContratoIA`

### 2. Criar o IAM User

1. Va em **IAM** → **Users** → **Create user**
2. Nome: `terraform-ci`
3. **NAO** marque "Provide user access to the AWS Management Console"
4. Em **Permissions** → **Attach policies directly**
5. Busque e selecione `ContratoIA-Terraform-CI`
6. Crie o user

### 3. Gerar Access Key

1. Clique no user `terraform-ci`
2. Aba **Security credentials** → **Create access key**
3. Selecione **Third-party service** (GitHub Actions)
4. Copie o **Access Key ID** e **Secret Access Key**
5. **IMPORTANTE:** salve a secret key agora — ela nao sera mostrada novamente

### 4. Configurar no GitHub

Va em `contrato-ia-infra` → **Settings** → **Secrets and variables** → **Actions**:

| Secret | Valor |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Access Key do user `terraform-ci` |
| `AWS_SECRET_ACCESS_KEY` | Secret Key do user `terraform-ci` |
| `TF_VAR_DB_PASSWORD` | Senha forte que voce escolher pro banco |
| `TF_VAR_CLAUDE_API_KEY` | Sua chave da API Anthropic |

### Principio de menor privilegio

Esta policy permite APENAS:

- **EC2**: criar/destruir instancias na regiao `sa-east-1`
- **VPC**: criar/destruir VPCs, subnets, SGs, IGW, EIPs
- **RDS**: criar/destruir instancias PostgreSQL
- **S3**: gerenciar buckets com prefixo `contrato-ia-*`
- **SQS**: gerenciar filas com prefixo `contrato-ia-*`
- **Secrets Manager**: gerenciar secrets em `contrato-ia/*`
- **CloudWatch**: gerenciar log groups em `/contrato-ia/*`
- **IAM**: criar roles/profiles com prefixo `contrato-ia-*`
- **Terraform State**: ler/escrever no bucket de state + DynamoDB lock

NAO permite:
- Acesso a outros recursos fora do prefixo `contrato-ia`
- Operacoes em outras regioes (exceto EC2/VPC limitado a sa-east-1)
- Criar outros IAM users ou policies
- Acessar billing, organizations, etc

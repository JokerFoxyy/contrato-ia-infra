# TASK-2 — Integrar módulo Cloudflare no environment production

## Referência SDD
Seção 3.2 e 3.3 — Integração nos environments + Provider Cloudflare

## Dependências
TASK-1 (módulo cloudflare deve existir)

## Contexto
O environment production em `environments/production/main.tf` já usa os módulos AWS (networking, storage, queue, secrets, compute, codedeploy). Precisamos adicionar o provider Cloudflare e referenciar o novo módulo.

## O que fazer

### Modificar `environments/production/main.tf`

**Before** (linha 10-13):
```hcl
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
  }
}
```

**After:**
```hcl
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
  }
  cloudflare = {
    source  = "cloudflare/cloudflare"
    version = "~> 5.0"
  }
}
```

Adicionar provider e módulo após o bloco `provider "aws"`:
```hcl
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

module "cloudflare" {
  source = "../../modules/cloudflare"

  zone_id      = var.cloudflare_zone_id
  domain       = var.domain
  api_ip       = module.compute.public_ip
  auth_ip      = module.compute.public_ip
  vercel_cname = var.vercel_cname
}
```

### Modificar `environments/production/variables.tf`
Adicionar variáveis:
- `cloudflare_api_token` (string, sensitive)
- `cloudflare_zone_id` (string)
- `domain` (string, default `"contratoai.com.br"`)
- `vercel_cname` (string, default `"cname.vercel-dns.com"`)

### Modificar `environments/production/terraform.tfvars`
Adicionar:
```hcl
domain              = "contratoai.com.br"
cors_origins        = ["https://contratoai.com.br", "https://www.contratoai.com.br"]
keycloak_issuer_uri = "https://auth.contratoai.com.br/realms/contrato-ia"
```

## Notas de implementação
- `cloudflare_api_token` e `cloudflare_zone_id` NÃO vão no tfvars — passados via `TF_VAR_*`
- `cors_origins` atualizado de Vercel URL para domínio real
- O módulo cloudflare depende de `module.compute.public_ip`, então precisa que compute exista

## Critério de aceite
- [ ] Provider cloudflare adicionado em `required_providers`
- [ ] Módulo cloudflare referenciado com variáveis corretas
- [ ] Variáveis `cloudflare_api_token` e `cloudflare_zone_id` marcadas como sensitive
- [ ] `cors_origins` atualizado para domínio real
- [ ] `terraform validate` passa no environment production

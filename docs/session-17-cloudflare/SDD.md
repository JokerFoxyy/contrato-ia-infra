# SDD — Sessão 17: Cloudflare + Domínio

## 1. Contexto e Problema

O ContratoIA possui toda a infraestrutura AWS definida em Terraform (EC2, RDS, S3, SQS, Secrets Manager) e o frontend deployado no Vercel, mas não há domínio customizado nem camada de proteção DNS/CDN na frente dos serviços.

Sem o Cloudflare configurado antes do deploy, a API ficaria exposta diretamente pelo IP público do EC2 — sem SSL gerenciado, sem proteção DDoS, sem WAF, e sem cache. Qualquer mudança de IP exigiria atualizar todos os clients manualmente.

O domínio escolhido é `contratoai.com.br`, com subdomínios `api.contratoai.com.br` (backend) e `auth.contratoai.com.br` (Keycloak). O registro será feito no Registro.br e o DNS gerenciado pelo Cloudflare (plano Free).

## 2. Escopo da Correção

### O que muda

| Componente | Mudança |
|---|---|
| Terraform (infra) | Novo módulo `modules/cloudflare/` com zona DNS, records A/CNAME, SSL settings, security rules |
| Staging env | Referência ao módulo cloudflare com variáveis de staging |
| Production env | Referência ao módulo cloudflare com variáveis de production |
| Variables | Novas variáveis: `cloudflare_api_token`, `cloudflare_zone_id`, `domain` |
| Backend (CORS) | Atualizar `cors_origins` nos tfvars para usar domínio real |
| Secrets | Atualizar `keycloak_issuer_uri` para usar `auth.contratoai.com.br` |

### O que NÃO muda

- Módulos AWS existentes (networking, compute, storage, queue, secrets, database) — zero alterações
- Código do backend Java — nenhuma mudança
- Código do frontend Angular — nenhuma mudança
- Workflows GitHub Actions — nenhuma mudança
- Estrutura de pastas do Terraform existente

## 3. Design da Solução

### 3.1 Novo módulo `modules/cloudflare/`

Módulo Terraform dedicado para gerenciar todos os recursos Cloudflare:

```hcl
# modules/cloudflare/main.tf

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

# --- DNS Records ---

# Frontend: contratoai.com.br → Vercel (CNAME)
resource "cloudflare_dns_record" "frontend_root" {
  zone_id = var.zone_id
  name    = "@"
  type    = "CNAME"
  content = var.vercel_cname
  proxied = true
  ttl     = 1  # auto quando proxied
}

# Frontend: www → root redirect
resource "cloudflare_dns_record" "frontend_www" {
  zone_id = var.zone_id
  name    = "www"
  type    = "CNAME"
  content = var.domain
  proxied = true
  ttl     = 1
}

# Backend API: api.contratoai.com.br → EC2 Elastic IP
resource "cloudflare_dns_record" "api" {
  zone_id = var.zone_id
  name    = "api"
  type    = "A"
  content = var.api_ip
  proxied = true
  ttl     = 1
}

# Keycloak: auth.contratoai.com.br → EC2 Elastic IP
resource "cloudflare_dns_record" "auth" {
  zone_id = var.zone_id
  name    = "auth"
  type    = "A"
  content = var.auth_ip
  proxied = true
  ttl     = 1
}

# --- SSL/TLS ---

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = var.zone_id
  setting_id = "ssl"
  value      = "full"
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = var.zone_id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = var.zone_id
  setting_id = "min_tls_version"
  value      = "1.2"
}

# --- Security ---

resource "cloudflare_zone_setting" "security_level" {
  zone_id    = var.zone_id
  setting_id = "security_level"
  value      = "medium"
}

resource "cloudflare_zone_setting" "browser_check" {
  zone_id    = var.zone_id
  setting_id = "browser_check"
  value      = "on"
}

# --- Performance ---

resource "cloudflare_zone_setting" "minify_js" {
  zone_id    = var.zone_id
  setting_id = "minify"
  value      = jsonencode({ css = "on", html = "on", js = "on" })
}

resource "cloudflare_zone_setting" "brotli" {
  zone_id    = var.zone_id
  setting_id = "brotli"
  value      = "on"
}
```

### 3.2 Integração nos environments

Ambos `production/main.tf` e `staging/main.tf` referenciam o módulo:

```hcl
module "cloudflare" {
  source = "../../modules/cloudflare"

  zone_id      = var.cloudflare_zone_id
  domain       = var.domain
  api_ip       = module.compute.public_ip
  auth_ip      = module.compute.public_ip  # Keycloak no mesmo EC2
  vercel_cname = var.vercel_cname
}
```

### 3.3 Provider Cloudflare

Adicionado no bloco `terraform` e `provider` dos environments:

```hcl
required_providers {
  cloudflare = {
    source  = "cloudflare/cloudflare"
    version = "~> 5.0"
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
```

## 4. Fluxo após a correção

```
                        ┌─────────────────┐
                        │   Registro.br   │
                        │ contratoai.com.br│
                        │ NS → Cloudflare │
                        └────────┬────────┘
                                 │
                        ┌────────▼────────┐
                        │   Cloudflare    │
                        │   (DNS + CDN)   │
                        │   SSL/TLS Full  │
                        │   WAF + DDoS    │
                        └────────┬────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
     ┌────────▼────────┐ ┌──────▼──────┐ ┌────────▼────────┐
     │ contratoai.com.br│ │ api.contra..│ │ auth.contra..   │
     │ CNAME → Vercel  │ │ A → EC2 EIP │ │ A → EC2 EIP     │
     │ (Frontend)      │ │ (Backend)   │ │ (Keycloak)      │
     └─────────────────┘ └─────────────┘ └─────────────────┘
              │                  │                  │
     ┌────────▼────────┐ ┌──────▼──────┐ ┌────────▼────────┐
     │   Vercel CDN    │ │ EC2:8080    │ │ EC2:8180        │
     │   Angular 19    │ │ Spring Boot │ │ Keycloak 24     │
     └─────────────────┘ └─────────────┘ └─────────────────┘
```

## 5. Arquivos a modificar/criar

| Arquivo | Tipo | Descrição |
|---|---|---|
| `modules/cloudflare/main.tf` | **CRIAR** | Recursos Cloudflare (DNS, SSL, security) |
| `modules/cloudflare/variables.tf` | **CRIAR** | Variáveis do módulo |
| `modules/cloudflare/outputs.tf` | **CRIAR** | Outputs (hostnames, nameservers) |
| `environments/production/main.tf` | MODIFICAR | Adicionar provider cloudflare + módulo |
| `environments/production/variables.tf` | MODIFICAR | Adicionar variáveis cloudflare |
| `environments/production/terraform.tfvars` | MODIFICAR | Adicionar valores cloudflare |
| `environments/staging/main.tf` | MODIFICAR | Adicionar provider cloudflare + módulo |
| `environments/staging/variables.tf` | MODIFICAR | Adicionar variáveis cloudflare |
| `environments/staging/terraform.tfvars` | MODIFICAR | Adicionar valores cloudflare |
| `CLAUDE.md` | MODIFICAR | Documentar módulo cloudflare |

## 6. Critérios de Aceite

- [ ] Módulo `modules/cloudflare/` criado com DNS records para root, www, api, auth
- [ ] SSL/TLS configurado como "Full" com TLS mínimo 1.2
- [ ] Always Use HTTPS habilitado
- [ ] Security level "medium" + browser integrity check ativado
- [ ] Brotli compression habilitado
- [ ] `terraform plan` roda sem erros em staging e production
- [ ] Variáveis sensíveis (`cloudflare_api_token`) marcadas como `sensitive = true`
- [ ] CLAUDE.md atualizado com documentação do módulo Cloudflare
- [ ] Nenhum módulo AWS existente foi alterado (apenas referências nos environments)

## 7. Considerações adicionais

### Segurança
- O `cloudflare_api_token` deve ter escopo mínimo: apenas permissão de editar DNS e Zone Settings para a zona `contratoai.com.br`
- O token NUNCA deve ser commitado — passar via `TF_VAR_cloudflare_api_token`
- Com Cloudflare Proxy ativado, o IP real do EC2 fica oculto (proteção DDoS)

### Pré-requisitos manuais (usuário)
1. Registrar `contratoai.com.br` no Registro.br
2. Criar conta Cloudflare e adicionar o domínio
3. Trocar nameservers no Registro.br para os do Cloudflare
4. Gerar API Token no Cloudflare (Edit Zone DNS + Zone Settings)
5. Anotar o Zone ID do dashboard Cloudflare

### Débito técnico
- Quando migrar o frontend para domínio próprio (fora Vercel), o CNAME do root precisará ser atualizado
- Page Rules e Cache Rules podem ser adicionados futuramente (sessão 29 — Observabilidade)
- WAF rules customizadas (rate limiting por país, block de bots) ficam para quando houver tráfego real

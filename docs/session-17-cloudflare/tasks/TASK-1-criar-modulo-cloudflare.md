# TASK-1 — Criar módulo Terraform Cloudflare

## Referência SDD
Seção 3.1 — Novo módulo `modules/cloudflare/`

## Dependências
Nenhuma — task independente.

## Contexto
O projeto não possui nenhum recurso Cloudflare no Terraform. Esta task cria o módulo reutilizável que será referenciado pelos environments staging e production.

## O que fazer

### Criar `modules/cloudflare/main.tf`
Recursos:
- `cloudflare_dns_record` — root (CNAME → Vercel), www (CNAME → root), api (A → EC2 IP), auth (A → EC2 IP)
- `cloudflare_zone_setting` — ssl (full), always_use_https, min_tls_version (1.2), security_level (medium), browser_check, brotli

### Criar `modules/cloudflare/variables.tf`
Variáveis:
- `zone_id` (string, obrigatória)
- `domain` (string, obrigatória)
- `api_ip` (string, obrigatória) — IP do EC2 backend
- `auth_ip` (string, obrigatória) — IP do EC2 Keycloak
- `vercel_cname` (string, default `"cname.vercel-dns.com"`)

### Criar `modules/cloudflare/outputs.tf`
Outputs:
- `frontend_hostname` — hostname do frontend
- `api_hostname` — hostname da API
- `auth_hostname` — hostname do Keycloak

## Notas de implementação
- Usar provider `cloudflare/cloudflare` versão `~> 5.0`
- Todos os records com `proxied = true` para ocultar IP real
- `ttl = 1` (auto) quando proxied — é o comportamento padrão do Cloudflare

## Critério de aceite
- [ ] Arquivos `main.tf`, `variables.tf`, `outputs.tf` criados em `modules/cloudflare/`
- [ ] Provider cloudflare declarado no `required_providers` do módulo
- [ ] 4 DNS records (root, www, api, auth)
- [ ] 6 zone settings (ssl, https, tls, security, browser_check, brotli)
- [ ] `terraform validate` passa no módulo isolado

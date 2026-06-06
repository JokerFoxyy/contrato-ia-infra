# TASK-4 — Atualizar documentação (CLAUDE.md)

## Referência SDD
Seção 5 — Arquivos a modificar

## Dependências
TASK-1 (módulo deve existir para documentar)

## Contexto
O CLAUDE.md do repo de infra documenta a arquitetura e módulos. O novo módulo Cloudflare precisa ser documentado para manter consistência.

## O que fazer

### Modificar `CLAUDE.md`

Adicionar na seção "Modular structure":
```
- **cloudflare/** — Cloudflare DNS, SSL/TLS, security settings, CDN proxy
```

Adicionar nova seção após "Cost Estimate":
```markdown
## DNS & CDN (Cloudflare)

Domain: `contratoai.com.br` (registered at Registro.br, DNS managed by Cloudflare)

| Subdomínio | Destino | Tipo |
|---|---|---|
| contratoai.com.br | Vercel | CNAME (proxied) |
| www.contratoai.com.br | contratoai.com.br | CNAME (proxied) |
| api.contratoai.com.br | EC2 Elastic IP | A (proxied) |
| auth.contratoai.com.br | EC2 Elastic IP | A (proxied) |

SSL: Full mode (Cloudflare → origin uses self-signed or Let's Encrypt)
TLS minimum: 1.2
Always HTTPS: enabled

Required env vars for Terraform:
- `TF_VAR_cloudflare_api_token` — Cloudflare API token (Edit Zone DNS + Zone Settings)
- `TF_VAR_cloudflare_zone_id` — Zone ID from Cloudflare dashboard
```

## Critério de aceite
- [ ] Módulo cloudflare listado na seção "Modular structure"
- [ ] Nova seção "DNS & CDN" com tabela de subdomínios
- [ ] Variáveis de ambiente documentadas

# TASK-2 — Configurar Nginx como reverse proxy

## Dependências
TASK-1

## O que fazer
- Criar `nginx/nginx.conf` com rotas:
  - `api.contratoai.com.br` → `backend:8080`
  - `auth.contratoai.com.br` → `keycloak:8180`
- Adicionar serviço Nginx no docker-compose.prod.yml
- Porta 443 (HTTPS via Cloudflare) e 80 (redirect)
- SSL mode: Cloudflare Full — origin pode usar self-signed ou HTTP interno

## Critério de aceite
- [ ] Nginx roteia corretamente por hostname
- [ ] `api.contratoai.com.br` chega no backend
- [ ] `auth.contratoai.com.br` chega no Keycloak

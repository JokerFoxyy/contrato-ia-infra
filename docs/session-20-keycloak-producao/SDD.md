# SDD — Sessão 20: Keycloak Produção

## 1. Contexto e Problema

O Keycloak roda localmente via Docker Compose na porta 8180 para desenvolvimento. Em produção, precisamos de um Keycloak acessível em `auth.contratoai.com.br` com realm configurado, client credentials para o frontend, e HTTPS.

Sem Keycloak em produção, nenhum usuário consegue autenticar — o backend rejeita todos os requests por falta de JWT válido.

## 2. Escopo da Correção

### O que muda

| Componente | Mudança |
|---|---|
| EC2 (Docker Compose prod) | Adicionar serviço Keycloak ao compose |
| Keycloak | Criar realm `contrato-ia`, client `frontend-app`, roles |
| Cloudflare | Record `auth.contratoai.com.br` já existe (sessão 17) |
| Backend config | Atualizar `KEYCLOAK_ISSUER_URI` no Secrets Manager |
| Frontend config | Atualizar `environment.prod.ts` com URL do Keycloak |

### O que NÃO muda

- Código Java do backend (SecurityConfig já lê issuer de config)
- Módulos Terraform AWS
- Lógica de autenticação (JWT validation já funciona)

## 3. Design da Solução

- Keycloak 24 rodando no Docker Compose de produção na porta 8180
- Nginx reverse proxy no EC2 para rotear `auth.contratoai.com.br` → `:8180`
- Realm export do dev para importar em produção
- PostgreSQL compartilhado (database separado: `keycloakdb`)

## 4. Fluxo após a correção

```
Browser ──► auth.contratoai.com.br ──► Cloudflare ──► EC2:443 ──► Nginx ──► Keycloak:8180
                                                                     │
                                                                     └──► Backend:8080
```

## 5. Arquivos a modificar/criar

| Arquivo | Repo | Tipo |
|---|---|---|
| `docker-compose.prod.yml` | backend | MODIFICAR — adicionar Keycloak |
| `nginx/nginx.conf` | backend/infra | CRIAR — reverse proxy |
| `keycloak/realm-export.json` | backend | CRIAR — realm config |
| `environments/production/terraform.tfvars` | infra | MODIFICAR — keycloak_issuer_uri |
| `src/environments/environment.prod.ts` | frontend | MODIFICAR — Keycloak URL |

## 6. Critérios de Aceite

- [ ] Keycloak acessível em `https://auth.contratoai.com.br`
- [ ] Realm `contrato-ia` com client `frontend-app` configurado
- [ ] Login funciona no frontend apontando para produção
- [ ] Backend valida JWT emitido pelo Keycloak de produção
- [ ] Roles `user`, `admin` configuradas
- [ ] Admin console acessível (com credenciais seguras)

## 7. Considerações adicionais

- Credenciais do admin Keycloak no Secrets Manager (nunca hardcoded)
- Considerar Keycloak em container separado do EC2 futuramente (quando escalar)
- Backup periódico do database `keycloakdb`

# TASK-1 — Adicionar Keycloak ao Docker Compose de produção

## Dependências
Sessão 19 (docker-compose.prod.yml deve existir)

## O que fazer
- Adicionar serviço `keycloak` no `docker-compose.prod.yml`
- Imagem: `quay.io/keycloak/keycloak:24.0`
- Porta: 8180 (interna)
- Database: PostgreSQL compartilhado, database `keycloakdb`
- Volume para themes/config
- Health check

## Critério de aceite
- [ ] `docker-compose up keycloak` sobe sem erros
- [ ] Keycloak responde em `localhost:8180`

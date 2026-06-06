# TASK-3 — Configurar realm e client no Keycloak

## Dependências
TASK-1 + TASK-2

## O que fazer
- Exportar realm do Keycloak de dev (`realm-export.json`)
- Importar no Keycloak de produção
- Configurar client `frontend-app`:
  - Valid redirect URIs: `https://contratoai.com.br/*`
  - Web origins: `https://contratoai.com.br`
  - Access type: public (SPA)
- Criar roles: `user`, `admin`
- Criar usuário admin com credenciais fortes

## Critério de aceite
- [ ] Realm `contrato-ia` existe em produção
- [ ] Client `frontend-app` configurado com URLs corretas
- [ ] Login funciona via frontend
- [ ] JWT contém roles corretas

# TASK-3 — Integrar módulo Cloudflare no environment staging

## Referência SDD
Seção 3.2 e 3.3 — Integração nos environments + Provider Cloudflare

## Dependências
TASK-1 (módulo cloudflare deve existir). Paralela com TASK-2.

## Contexto
Mesma integração da TASK-2, mas para staging. Staging pode usar um subdomínio separado (ex: `staging-api.contratoai.com.br`) ou o mesmo domínio apontando para IP diferente.

## O que fazer

### Modificar `environments/staging/main.tf`
- Adicionar `cloudflare` no `required_providers`
- Adicionar `provider "cloudflare"`
- Adicionar `module "cloudflare"` com referência ao módulo

### Modificar `environments/staging/variables.tf`
- Adicionar mesmas variáveis cloudflare do production

### Modificar `environments/staging/terraform.tfvars`
```hcl
domain              = "contratoai.com.br"
cors_origins        = ["https://staging.contratoai.com.br"]
keycloak_issuer_uri = "https://auth-staging.contratoai.com.br/realms/contrato-ia"
```

## Notas de implementação
- Staging usa subdomínios com prefixo `staging-` ou `staging.` para diferenciar
- O módulo cloudflare cria records na mesma zona DNS — staging e production coexistem
- Para staging funcionar com subdomínios diferentes, o módulo pode receber um `prefix` opcional

## Critério de aceite
- [ ] Provider e módulo cloudflare integrados no staging
- [ ] Variáveis e tfvars atualizados
- [ ] `terraform validate` passa no environment staging

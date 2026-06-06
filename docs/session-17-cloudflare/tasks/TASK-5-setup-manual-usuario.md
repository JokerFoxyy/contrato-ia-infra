# TASK-5 — Setup manual do usuário (Registro.br + Cloudflare)

## Referência SDD
Seção 7 — Pré-requisitos manuais

## Dependências
Nenhuma — pode ser feita em paralelo com todas as outras tasks.
Esta task é executada PELO USUÁRIO, não pelo Claude.

## Contexto
O Terraform gerencia recursos Cloudflare via API, mas o domínio e a conta precisam ser criados manualmente pelo usuário.

## O que fazer (checklist do usuário)

### Passo 1 — Registrar domínio
- [ ] Acessar [registro.br](https://registro.br)
- [ ] Registrar `contratoai.com.br` (~R$40/ano)
- [ ] Confirmar e-mail de registro

### Passo 2 — Criar conta Cloudflare
- [ ] Acessar [dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up)
- [ ] Criar conta (plano Free)
- [ ] Adicionar site `contratoai.com.br`
- [ ] Anotar os 2 nameservers fornecidos pelo Cloudflare

### Passo 3 — Trocar nameservers
- [ ] No Registro.br, ir em "Alterar servidores DNS"
- [ ] Substituir os nameservers padrão pelos 2 do Cloudflare
- [ ] Aguardar propagação (até 24h, geralmente <1h)

### Passo 4 — Gerar API Token
- [ ] No Cloudflare, ir em My Profile → API Tokens
- [ ] Create Token → "Edit zone DNS" template
- [ ] Adicionar permissão extra: Zone Settings → Edit
- [ ] Restringir à zona `contratoai.com.br`
- [ ] Copiar o token gerado

### Passo 5 — Anotar Zone ID
- [ ] No dashboard Cloudflare, selecionar `contratoai.com.br`
- [ ] Na sidebar direita, copiar o "Zone ID"

### Passo 6 — Configurar variáveis de ambiente
```bash
export TF_VAR_cloudflare_api_token="seu-token-aqui"
export TF_VAR_cloudflare_zone_id="seu-zone-id-aqui"
```

## Critério de aceite
- [ ] Domínio `contratoai.com.br` registrado e ativo
- [ ] Nameservers do Cloudflare configurados no Registro.br
- [ ] Status "Active" no dashboard Cloudflare
- [ ] API Token gerado com permissões corretas
- [ ] Zone ID anotado

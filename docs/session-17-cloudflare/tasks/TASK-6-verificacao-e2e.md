# TASK-6 — Verificação end-to-end

## Referência SDD
Seção 6 — Critérios de Aceite (validação final)

## Dependências
Todas as tasks anteriores (TASK-1 a TASK-5).

## Contexto
Validação final que garante que todo o Terraform está correto e pronto para `terraform apply` quando a infraestrutura AWS for criada (sessão 18).

## O que fazer

### Validação Terraform
```bash
cd environments/production
terraform init
terraform validate

cd ../staging
terraform init
terraform validate
```

### Validação DNS (após TASK-5 do usuário)
```bash
# Verificar nameservers
dig NS contratoai.com.br

# Verificar propagação (após terraform apply)
dig A api.contratoai.com.br
dig A auth.contratoai.com.br
dig CNAME contratoai.com.br
```

### Checklist final

- [ ] `terraform init` passa em production sem erros
- [ ] `terraform init` passa em staging sem erros
- [ ] `terraform validate` passa em production
- [ ] `terraform validate` passa em staging
- [ ] `terraform plan` mostra apenas recursos Cloudflare como "to create" (nenhum recurso AWS alterado)
- [ ] Nenhum secret hardcoded nos arquivos commitados
- [ ] CLAUDE.md atualizado com documentação Cloudflare
- [ ] Estrutura de pastas `docs/session-17-cloudflare/` completa com SDD + tasks
- [ ] Domínio ativo no Cloudflare com status "Active" (depende de TASK-5)

## Notas
- O `terraform plan` vai funcionar mesmo sem AWS ainda — os módulos AWS vão falhar se não houver credentials, mas o módulo Cloudflare pode ser planejado isoladamente
- O `terraform apply` do Cloudflare só faz sentido APÓS o domínio estar ativo (TASK-5) e idealmente JUNTO com a infra AWS (sessão 18)

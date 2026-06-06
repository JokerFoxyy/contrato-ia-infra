# Guia Manual — Setup Cloudflare + Domínio

Este guia detalha TUDO que você precisa fazer manualmente para a sessão 17.
O Claude cuida do código Terraform — você cuida da conta e domínio.

Tempo estimado: ~30 minutos (+ até 24h de propagação DNS)

---

## Passo 1 — Registrar domínio no Registro.br

1. Acesse [https://registro.br](https://registro.br)
2. Na barra de busca, pesquise `contratoai.com.br`
3. Se disponível, clique em **"Registrar"**
4. Crie uma conta no Registro.br (se não tiver) com seus dados pessoais/CNPJ
5. Escolha o período: **1 ano** (~R$40)
6. Finalize o pagamento (PIX, boleto ou cartão)
7. Confirme o e-mail de verificação que vai chegar na sua caixa

> ⚠️ O domínio pode levar alguns minutos para ficar ativo após o pagamento.
> Você vai receber um e-mail do Registro.br confirmando a ativação.

**Resultado esperado:** Domínio `contratoai.com.br` ativo no painel do Registro.br.

---

## Passo 2 — Criar conta no Cloudflare

1. Acesse [https://dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up)
2. Crie a conta com e-mail e senha
3. Confirme o e-mail

**Resultado esperado:** Acesso ao dashboard do Cloudflare.

---

## Passo 3 — Adicionar domínio no Cloudflare

1. No dashboard, clique em **"Add a site"** (ou "Adicionar um site")
2. Digite: `contratoai.com.br`
3. Selecione o plano **Free** (R$0) → clique "Continue"
4. O Cloudflare vai scanear os DNS records existentes
   - Provavelmente vai mostrar os records padrão do Registro.br
   - **Não se preocupe** — o Terraform vai sobrescrever tudo depois
   - Pode deletar qualquer record que aparecer ou deixar — tanto faz
5. Clique **"Continue"**
6. O Cloudflare vai mostrar **2 nameservers**, algo como:
   ```
   aria.ns.cloudflare.com
   chad.ns.cloudflare.com
   ```
7. **ANOTE esses 2 nameservers** — você vai precisar no próximo passo

**Resultado esperado:** Site adicionado no Cloudflare com status "Pending Nameserver Update".

---

## Passo 4 — Trocar nameservers no Registro.br

1. Acesse [https://registro.br](https://registro.br) e faça login
2. Vá em **"Meus domínios"** → clique em `contratoai.com.br`
3. Procure a seção **"Servidores DNS"** ou **"Alterar servidores DNS"**
4. Remova os nameservers atuais (provavelmente `a.dns.br`, `b.dns.br`, etc.)
5. Adicione os **2 nameservers do Cloudflare** que você anotou:
   ```
   Servidor 1: aria.ns.cloudflare.com
   Servidor 2: chad.ns.cloudflare.com
   ```
   (os nomes exatos vão ser diferentes — use os que o Cloudflare te deu)
6. Salve as alterações
7. Aguarde a propagação:
   - Geralmente leva **10 minutos a 2 horas**
   - Em casos raros, pode levar até 24h
   - O Cloudflare te envia um e-mail quando detectar que os nameservers mudaram

> 💡 **Como verificar se propagou:**
> Abra o terminal e rode:
> ```bash
> nslookup -type=NS contratoai.com.br
> ```
> Quando aparecer os nameservers do Cloudflare, está pronto.
>
> Ou use: [https://dnschecker.org/#NS/contratoai.com.br](https://dnschecker.org/#NS/contratoai.com.br)

**Resultado esperado:** Status no Cloudflare muda de "Pending" para **"Active"**.

---

## Passo 5 — Gerar API Token no Cloudflare

O Terraform precisa de um token para gerenciar o DNS e settings via API.

1. No Cloudflare, clique no ícone do seu perfil (canto superior direito)
2. Vá em **"My Profile"** → **"API Tokens"**
3. Clique **"Create Token"**
4. Use o template **"Edit zone DNS"** → clique "Use template"
5. Configure as permissões:

   | Permissão | Tipo | Valor |
   |---|---|---|
   | Zone — DNS | Edit | ✅ (já vem) |
   | Zone — Zone Settings | Edit | ➕ Adicionar esta |

6. Em **"Zone Resources"**, selecione:
   - Include → Specific zone → `contratoai.com.br`
   
   (isso restringe o token para só mexer nesse domínio — segurança)

7. Clique **"Continue to summary"** → **"Create Token"**
8. **COPIE O TOKEN IMEDIATAMENTE** — ele só aparece uma vez!
   - Guarde em local seguro (gerenciador de senhas, não em arquivo texto)

> ⚠️ Se perder o token, precisa deletar e criar outro. Não tem como recuperar.

**Resultado esperado:** Token copiado e guardado. Formato: algo como `v1.0-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

---

## Passo 6 — Anotar o Zone ID

1. No dashboard do Cloudflare, clique em `contratoai.com.br`
2. Na página de Overview, olhe a **sidebar direita**
3. Procure a seção **"API"**
4. Copie o **"Zone ID"** — é uma string hexadecimal tipo `a1b2c3d4e5f6...`

**Resultado esperado:** Zone ID copiado. Formato: 32 caracteres hexadecimais.

---

## Passo 7 — Me passar os dados

Quando terminar tudo, me diga:

1. ✅ "Domínio registrado" — confirmo que `contratoai.com.br` está ativo
2. ✅ "Cloudflare ativo" — status mudou pra Active
3. ✅ "Tenho o API Token" — não precisa me mostrar, só confirmar
4. ✅ "Tenho o Zone ID" — me passa o Zone ID (não é sensível)

Com isso eu finalizo a configuração do Terraform e a gente valida tudo junto.

---

## Passo 8 — Configurar variáveis de ambiente (depois)

Quando formos rodar o Terraform (sessão 18), você vai precisar setar:

```bash
# No terminal antes de rodar terraform apply
export TF_VAR_cloudflare_api_token="seu-token-aqui"
export TF_VAR_cloudflare_zone_id="seu-zone-id-aqui"
```

Ou criar um arquivo `.env` local (que NÃO vai pro git):
```bash
# .env (NÃO COMMITAR)
TF_VAR_cloudflare_api_token=v1.0-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TF_VAR_cloudflare_zone_id=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

---

## Resumo visual

```
Você faz:                          Tempo estimado:
─────────────────────────────────────────────────
[1] Registrar domínio              ~10 min
[2] Criar conta Cloudflare         ~5 min
[3] Adicionar domínio no CF        ~5 min
[4] Trocar nameservers             ~5 min + espera
[5] Gerar API Token                ~5 min
[6] Anotar Zone ID                 ~1 min
[7] Me avisar                      ~1 min
                                   ─────────
                          Total:   ~30 min + propagação DNS
```

---

## Custos

| Item | Custo |
|---|---|
| Domínio `contratoai.com.br` (Registro.br) | ~R$40/ano |
| Cloudflare (plano Free) | R$0 |
| **Total** | **~R$40/ano** |

# SDD — Sessão 29: Observabilidade

## 1. Contexto e Problema

O backend envia logs estruturados (JSON via logstash-encoder) para CloudWatch, mas não há alertas, métricas customizadas, nem dashboards de monitoramento. Se a API cair ou tiver spike de erros, ninguém é notificado.

## 2. Escopo da Correção

### O que muda

| Componente | Mudança |
|---|---|
| Terraform | CRIAR — CloudWatch Metric Filters, Alarms, SNS topic |
| CloudWatch Dashboard | CRIAR — dashboard com métricas principais |
| AWS GuardDuty | HABILITAR — detecção de ameaças managed |
| Backend | MODIFICAR — adicionar métricas customizadas (Micrometer) |
| Spring Actuator | CONFIGURAR — expor métricas para CloudWatch |

### O que NÃO muda

- Logging (já funciona com logstash-encoder)
- Código de negócio
- Frontend

## 3. Design da Solução

### Metric Filters (log patterns → métricas)
- `rate_limit_exceeded` — count de 429s
- `api_error_5xx` — count de erros 500
- `document_generation_failed` — count de falhas de geração
- `authentication_failed` — count de 401/403

### Alarms
- 5xx > 10 em 5 min → SNS email alert
- Rate limit > 50 em 5 min → SNS alert
- EC2 CPU > 80% por 5 min → SNS alert
- Disk usage > 85% → SNS alert

### GuardDuty
- Habilitar com Terraform (`aws_guardduty_detector`)
- Custo: ~$1/mês com pouco tráfego

### Micrometer + CloudWatch
- Adicionar `micrometer-registry-cloudwatch` ao backend
- Métricas: request count, latency p50/p95/p99, active connections

## 5. Arquivos a modificar/criar

| Arquivo | Tipo |
|---|---|
| `modules/monitoring/main.tf` | CRIAR |
| `modules/monitoring/variables.tf` | CRIAR |
| `modules/monitoring/outputs.tf` | CRIAR |
| `environments/production/main.tf` | MODIFICAR — add monitoring module |
| `pom.xml` | MODIFICAR — add micrometer-cloudwatch |
| `application.yml` | MODIFICAR — configure micrometer |

## 6. Critérios de Aceite

- [ ] Metric filters criados para 4 patterns
- [ ] 4 alarms configurados com SNS notification
- [ ] Dashboard CloudWatch com gráficos de métricas
- [ ] GuardDuty habilitado
- [ ] Micrometer enviando métricas para CloudWatch
- [ ] Alerta de teste recebido por email
- [ ] `terraform plan` mostra apenas novos recursos de monitoring

## 7. Considerações adicionais

- SNS topic com email do admin — não expor publicamente
- Considerar Slack webhook para alertas (futuro)
- GuardDuty findings revisados semanalmente

# TASK-4 — Verificação end-to-end

## Dependências
Todas as anteriores.

## O que fazer

- [ ] `terraform output` retorna todos os valores esperados
- [ ] SSH funciona: `ssh -i key.pem ec2-user@<IP>`
- [ ] Docker instalado no EC2: `docker --version`
- [ ] Security groups corretos: porta 8080, 443, 22 (restrito)
- [ ] S3 bucket acessível: `aws s3 ls s3://contrato-ia-production-documents`
- [ ] SQS queue existe: `aws sqs get-queue-url --queue-name contrato-ia-production-generation.fifo`
- [ ] Secrets Manager: `aws secretsmanager get-secret-value --secret-id contrato-ia-production`
- [ ] CloudWatch log group existe
- [ ] State remoto funcional: `terraform state list`
- [ ] CLAUDE.md atualizado com processo de deploy

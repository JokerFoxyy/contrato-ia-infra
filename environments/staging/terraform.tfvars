project     = "contrato-ia"
environment = "staging"
aws_region  = "sa-east-1"

ec2_instance_type = "t3.micro"
db_instance_class = "db.t3.micro"
db_username       = "contrato_user"

cors_origins        = ["https://contrato-ia-frontend.vercel.app"]
ssh_allowed_cidrs   = []
keycloak_issuer_uri = "https://auth-staging.contrato-ia.com.br/realms/contrato-ia"

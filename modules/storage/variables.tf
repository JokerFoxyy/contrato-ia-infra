variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "cors_origins" {
  description = "Allowed CORS origins for presigned URLs"
  type        = list(string)
  default     = ["https://contrato-ia-frontend.vercel.app"]
}

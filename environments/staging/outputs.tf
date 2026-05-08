output "backend_public_ip" {
  value = module.compute.public_ip
}

output "database_endpoint" {
  value = module.database.endpoint
}

output "s3_bucket_name" {
  value = module.storage.bucket_name
}

output "sqs_generation_queue_url" {
  value = module.queue.generation_queue_url
}

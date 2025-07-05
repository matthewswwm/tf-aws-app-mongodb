output "mongodb_public_ip" {
  description = "The public IP of the MongoDB instance"
  value       = aws_instance.mongodb_instance.public_ip
}

output "mongodb_private_ip" {
  description = "Private IP of the MongoDB EC2 instance"
  value       = aws_instance.mongodb_instance.private_ip
}

output "s3_bucket_id" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.mongdb_bucket.id
}

output "s3_backups_http_url" {
  description = "HTTP URL to access the backups directory in S3"
  value       = "https://${aws_s3_bucket.mongdb_bucket.bucket}.s3.${var.aws_region}.amazonaws.com/backups/"
}

output "tasky_app_url" {
  description = "Public URL to access the Tasky"
  value       = "http://${kubernetes_ingress_v1.app_ingress.status[0].load_balancer[0].ingress[0].hostname}"
}

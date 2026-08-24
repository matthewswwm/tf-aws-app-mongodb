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

# For subsequent project's data source
# output "eks_cluster_name" {
#   description = "The EKS cluster name for used as a data source"
#   value       = module.eks.cluster_name
# }

# output "eks_cluster_endpoint" {
#   description = "The EKS cluster endpoint"
#   value       = module.eks.cluster_endpoint
# }

# output "eks_cluster_ca" {
#   description = "The EKS cluster name"
#   value       = module.eks.cluster_certificate_authority_data[0].data
# }

output "mongodb_public_ip" {
  description = "The public IP of the MongoDB instance"
  value       = aws_instance.mongodb_instance.public_ip
}

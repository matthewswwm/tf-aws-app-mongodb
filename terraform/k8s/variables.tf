# EKS variables
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

# MongoDB variables
variable "mongo_tasky_username" {
  description = "The username value of the tasky user to access MongoDB"
  type        = string
  sensitive   = true
}

variable "mongo_tasky_password" {
  description = "The password value of the tasky user to access MongoDB"
  type        = string
  sensitive   = true
}

# K8s variables
variable "jwt_secret_key" {
  description = "Value of the SECRET_KEY used by tasky app"
  type        = string
  sensitive   = true
}

variable "textfile" {
  description = "The name of the text file being added to the application pod"
  type        = string
  default     = "me.txt"
}

## App-related
variable "image_name" {
  description = "The name of the image that contains the app"
  type        = string
}

variable "app_name" {
  description = "The name of the app"
  type        = string
  default     = "tasky"
}

variable "target_port" {
  description = "The port that the app is listening on"
  type        = string
  default     = "8080"
}

variable "service_port" {
  description = "The port exposed to service external connection"
  type        = string
  default     = "80"
}

# General variables
variable "aws_region" {
  description = "AWS region to use"
  type        = string
  default     = "eu-west-2"
}

variable "project_tag" {
  description = "The tag for the name/id of the project the resource is associated with. Can also be used in the name of resources"
  type        = string
}

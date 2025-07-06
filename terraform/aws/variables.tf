# MongoDB variables
variable "mongo_admin_username" {
  description = "The username value of the MongoDB admin created at start"
  type        = string
  sensitive   = true
}

variable "mongo_admin_password" {
  description = "The password value of the MongoDB admin created at start"
  type        = string
  sensitive   = true
}

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

# Instance variables
variable "key_name" {
  description = "The name of the AWS key pair resource"
  type        = string
}

variable "pub_key_file_path" {
  description = "Path to the public key file on the system"
  type        = string
}

variable "pri_key_file_path" {
  description = "Path to the private key file on the system"
  type        = string
}

variable "ssh_connection_user" {
  description = "The default SSH user used for the connection, determined by the AMI selected"
  type        = string
}

variable "mongodb_instance_type" {
  description = "The size used by the MongoDB instance"
  type        = string
  default     = "t2.medium"
}

# EKS variables
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_cluster_ver" {
  description = "Version of the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "eks_subnet_cidrs" {
  description = "List of subnet CIDRs for EKS"
  type        = list(string)
  default     = []
}

# Network variables
variable "vpc_cidr" {
  description = "The cidr block range of IP addresses for the virtual private cloud"
  type        = string
  default     = "192.0.0.0/16"
}

variable "subnet_cidr" {
  description = "The cidr block range of IP addresses for the subnet"
  type        = string
  default     = "192.0.0.0/24"
}

variable "aws_availability_zone" {
  description = "The availability zone within the provider region the resources will be running, e.g. eu-west-1a and ap-southeast-1b"
  type        = string
}

variable "additional_public_cidrs" {
  description = "For dynamically adding more security groups to support additional CIDRs. Note the rule will be for all protocols and ports"
  type        = list(any)
  default     = null
}

# K8s variables
# variable "jwt_secret_key" {
#   description = "Value of the SECRET_KEY used by tasky app"
#   type        = string
#   sensitive   = true
# }

# variable "textfile" {
#   description = "The name of the text file being added to the application pod"
#   type        = string
#   default     = "me.txt"
# }

# ## App-related
# variable "image_name" {
#   description = "The name of the image that contains the app"
#   type        = string
# }

# variable "app_name" {
#   description = "The name of the app"
#   type        = string
#   default     = "tasky"
# }

# variable "target_port" {
#   description = "The port that the app is listening on"
#   type        = string
#   default     = "8080"
# }

# variable "service_port" {
#   description = "The port exposed to service external connection"
#   type        = string
#   default     = "80"
# }

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

variable "owner_tag" {
  description = "Owner tag applied to all resources"
  type        = string
}

variable "environment_tag" {
  description = "Environment tag applied to all resources"
  type        = string
  default     = "DEV"
}

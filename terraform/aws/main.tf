# main.tf
# The main bulk of the Terraform code. Most of the AWS resources are located here.

terraform {
  required_version = ">= 1.11.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.90.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4.5"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_tag
      Owner       = var.owner_tag
      Environment = var.environment_tag
      ManagedBy   = "Terraform"
    }
  }
}

# Data section
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    # values = ["al2023-ami-2023.*-x86_64"] # Amazon Linux 2023
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"] # Amazon Linux 2
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Cloudinit section
data "cloudinit_config" "instance_config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "01_mongodb_install.sh"
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/templates/mongodb_install.sh.tftpl", {
      mongo_admin_username = var.mongo_admin_username,
      mongo_admin_password = var.mongo_admin_password,
      mongo_tasky_username = var.mongo_tasky_username,
      mongo_tasky_password = var.mongo_tasky_password
    })
  }
}

# Instance Section
resource "aws_key_pair" "aws_keypair" {
  key_name   = var.key_name
  public_key = file(var.pub_key_file_path)
}

resource "aws_instance" "mongodb_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.mongodb_instance_type
  subnet_id                   = aws_subnet.aws_subnet.id
  vpc_security_group_ids      = [aws_security_group.aws_sg.id]
  key_name                    = aws_key_pair.aws_keypair.key_name
  user_data                   = data.cloudinit_config.instance_config.rendered
  iam_instance_profile        = aws_iam_instance_profile.csp_admin_instance_profile.name
  user_data_replace_on_change = true

  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = var.ssh_connection_user
    private_key = file(var.pri_key_file_path)
  }

  # Create directories & chron entry
  provisioner "remote-exec" {
    inline = [
      "mkdir /tmp/scripts/",
      "mkdir /tmp/logs/",
      "(crontab -l 2>/dev/null; echo \"33 * * * * /bin/bash /tmp/scripts/mongodb_backup.sh >> /tmp/logs/mongodb_backup.log 2>&1\") | sudo crontab -"
    ]
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/mongodb_backup.sh.tftpl", {
      bucket_name          = aws_s3_bucket.mongdb_bucket.bucket,
      mongo_admin_username = var.mongo_admin_username,
      mongo_admin_password = var.mongo_admin_password
    })
    destination = "/tmp/scripts/mongodb_backup.sh"
  }

  ## Recursive changing of permissions to executables
  provisioner "remote-exec" {
    inline = [
      "chmod -R 755 /tmp/scripts/",
    ]
  }

  tags = {
    Name = "${var.project_tag}_MONGODB_INSTANCE"
  }
}

## IAM Section
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid    = "ec2AssumeRole"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "csp_admin_role" {
  name               = "${var.project_tag}-csp-admin-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "csp_admin_policy_attach" {
  role       = aws_iam_role.csp_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "csp_admin_instance_profile" {
  name = "${var.project_tag}-csp-admin-profile"
  role = aws_iam_role.csp_admin_role.name
}

# S3 bucket section
resource "aws_s3_bucket" "mongdb_bucket" {
  bucket_prefix = "mongo-tasky-bucket"
  force_destroy = true # DO NOT DO THIS IN PRODUCTION

  tags = {
    Name = "${var.project_tag}_MONGODB_BUCKET"
  }
}

resource "aws_s3_bucket_public_access_block" "mongdb_bucket_pub_access" {
  bucket = aws_s3_bucket.mongdb_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_object" "backups_folder" {
  bucket  = aws_s3_bucket.mongdb_bucket.id
  key     = "backups/"
  content = ""
}

## IAM section
data "aws_iam_policy_document" "mongdb_bucket_public_read" {
  statement {
    sid    = "PublicAccess"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
    ]

    resources = [
      aws_s3_bucket.mongdb_bucket.arn,
      "${aws_s3_bucket.mongdb_bucket.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "mongdb_bucket_pub_read_pol" {
  bucket = aws_s3_bucket.mongdb_bucket.id
  policy = data.aws_iam_policy_document.mongdb_bucket_public_read.json
}

# EKS module section
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_ver
  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }
  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  vpc_id                    = aws_vpc.aws_vpc.id
  subnet_ids                = [aws_subnet.eks_subnet_1.id, aws_subnet.eks_subnet_2.id]
  cluster_security_group_id = aws_security_group.aws_sg.id

  tags = {
    Project     = var.project_tag
    Owner       = var.owner_tag
    Environment = var.environment_tag
    ManagedBy   = "Terraform"
  }
}

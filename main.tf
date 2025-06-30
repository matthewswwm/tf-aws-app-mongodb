terraform {
  required_version = ">= 1.11.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.90.0"
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
## Needs to be out of date linux. Maybe an old Amazon linux 2 could work
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
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
    filename     = "01_ud_base.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/scripts/template.sh")
  }

  part {
    filename     = "02_template.sh"
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/templates/template.tftpl", {
      tf_var = var.tf_var
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
  user_data_replace_on_change = true

  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = var.ssh_connection_user
    private_key = file(var.pri_key_file_path)
  }

  # Copying entire directory
  provisioner "file" {
    source      = "${path.module}/scripts"
    destination = "/tmp/"
  }

  ## Recursive changing of permissions to executables
  provisioner "remote-exec" {
    inline = [
      "chmod -R 755 /tmp/scripts/",
    ]
  }

  tags = {
    Name = "${var.project_tag}_AWS_INSTANCE"
  }
}

# S3 bucket section
## Public access available
## No encryption

# EKS section
## Probably use the module
## Should this be in k8s section?

# IAM profile section
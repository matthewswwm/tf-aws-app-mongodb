# k8s.tf
# For everything related to the K8s provider & related resources. It relies on the AWS EKS module to be created in order to connect and apply the K8s resources.

terraform {
  required_version = ">= 1.11.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.90.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.37.1"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data section
data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

data "aws_instance" "mongodb_instance" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_tag}_MONGODB_INSTANCE"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# App section
resource "kubernetes_namespace" "app_ns" {
  metadata {
    name = var.app_name
  }
}

resource "kubernetes_secret" "app_secret" {
  metadata {
    name      = "${var.app_name}-env-secrets"
    namespace = kubernetes_namespace.app_ns.metadata[0].name
  }

  data = {
    MONGODB_URI = "mongodb://${var.mongo_tasky_username}:${var.mongo_tasky_password}@${data.aws_instance.mongodb_instance.private_ip}:27017/admin"
    SECRET_KEY  = var.jwt_secret_key
  }

  lifecycle {
    replace_triggered_by = [kubernetes_namespace.app_ns]
  }
}

resource "kubernetes_config_map" "text_file" {
  metadata {
    name      = var.textfile
    namespace = kubernetes_namespace.app_ns.metadata[0].name
  }
  data = {
    "${var.textfile}" = file("${path.module}/local_files/${var.textfile}")
  }
  lifecycle {
    replace_triggered_by = [kubernetes_namespace.app_ns]
  }
}

resource "kubernetes_deployment" "app_deployment" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.app_ns.metadata[0].name
    labels = {
      app = var.app_name
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = var.app_name
      }
    }
    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }
      spec {
        container {
          name  = var.app_name
          image = "${var.image_name}:latest"
          env_from {
            secret_ref {
              name = kubernetes_secret.app_secret.metadata[0].name
            }
          }
          port {
            container_port = var.target_port
          }
          volume_mount {
            name       = "text-volume"
            mount_path = "/tmp/${var.app_name}"
          }
        }
        volume {
          name = "text-volume"
          config_map {
            name = kubernetes_config_map.text_file.metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [kubernetes_namespace.app_ns]
  }
}

resource "kubernetes_cluster_role_binding" "app_admin_rb" {
  metadata {
    name = "${var.app_name}-admin-rb"
  }
  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = kubernetes_namespace.app_ns.metadata[0].name
  }
  lifecycle {
    replace_triggered_by = [kubernetes_namespace.app_ns]
  }
}

resource "kubernetes_service" "app_http_service" {
  metadata {
    name      = "${var.app_name}-service"
    namespace = kubernetes_namespace.app_ns.metadata[0].name
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = var.app_name
    }
    port {
      port        = var.service_port
      target_port = var.target_port
    }
  }
  lifecycle {
    replace_triggered_by = [kubernetes_namespace.app_ns]
  }
}

## Ingress section
resource "kubernetes_manifest" "alb_ingress_class_params" {
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "IngressClassParams"
    metadata = {
      name = "alb"
    }
    spec = {
      scheme = "internet-facing"
    }
  }
}

resource "kubernetes_ingress_class" "alb_ingress_class" {
  metadata {
    name = "alb"
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = "true"
    }
  }
  spec {
    controller = "eks.amazonaws.com/alb"
    parameters {
      api_group = "eks.amazonaws.com"
      kind      = "IngressClassParams"
      name      = "alb"
    }
  }
}

resource "kubernetes_ingress_v1" "app_ingress" {
  metadata {
    name      = "${var.app_name}-ingress"
    namespace = kubernetes_namespace.app_ns.metadata[0].name
  }
  spec {
    ingress_class_name = kubernetes_ingress_class.alb_ingress_class.metadata[0].name
    rule {
      http {
        path {
          path      = "/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service.app_http_service.metadata[0].name
              port {
                number = var.service_port
              }
            }
          }
        }
      }
    }
  }
}

# Wait some time in order for the hostname of the ingress to be populated. Has to be the final wait.
resource "null_resource" "wait_30_seconds" {
  provisioner "local-exec" {
    command = "sleep 30"
  }

  depends_on = [kubernetes_ingress_v1.app_ingress, kubernetes_deployment.app_deployment]
}
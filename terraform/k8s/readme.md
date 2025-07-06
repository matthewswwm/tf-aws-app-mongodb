# tf-aws-app-mongodb/k8s

## Description

The directory for the K8s resources that. Retrieves some data from AWS.

## Troubleshooting & debugging

General troubleshooting guide information should be added here.

### K8s resources not properly created on reapply

* In the K8s section, the `ConfigMap` & `Secret` terraform resources were not automatically re-created when the namespace was re-created
    * ~~`depends_on`~~ argument did not work
    * `replace_triggered_by` lifecycle property worked

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.90.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.37.1 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.37.1 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_cluster_role_binding.app_admin_rb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_config_map.text_file](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.app_deployment](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_ingress_class.alb_ingress_class](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_class) | resource |
| [kubernetes_ingress_v1.app_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_manifest.alb_ingress_class_params](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.app_ns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.app_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service.app_http_service](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [null_resource.wait_30_seconds](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_instance.mongodb_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instance) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | The name of the app | `string` | `"tasky"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to use | `string` | `"eu-west-2"` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | The name of the image that contains the app | `string` | n/a | yes |
| <a name="input_jwt_secret_key"></a> [jwt\_secret\_key](#input\_jwt\_secret\_key) | Value of the SECRET\_KEY used by tasky app | `string` | n/a | yes |
| <a name="input_mongo_tasky_password"></a> [mongo\_tasky\_password](#input\_mongo\_tasky\_password) | The password value of the tasky user to access MongoDB | `string` | n/a | yes |
| <a name="input_mongo_tasky_username"></a> [mongo\_tasky\_username](#input\_mongo\_tasky\_username) | The username value of the tasky user to access MongoDB | `string` | n/a | yes |
| <a name="input_project_tag"></a> [project\_tag](#input\_project\_tag) | The tag for the name/id of the project the resource is associated with. Can also be used in the name of resources | `string` | n/a | yes |
| <a name="input_service_port"></a> [service\_port](#input\_service\_port) | The port exposed to service external connection | `string` | `"80"` | no |
| <a name="input_target_port"></a> [target\_port](#input\_target\_port) | The port that the app is listening on | `string` | `"8080"` | no |
| <a name="input_textfile"></a> [textfile](#input\_textfile) | The name of the text file being added to the application pod | `string` | `"me.txt"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tasky_app_url"></a> [tasky\_app\_url](#output\_tasky\_app\_url) | Public URL to access the Tasky. If the the value is not ready, a refresh should get the value. |
<!-- END_TF_DOCS -->
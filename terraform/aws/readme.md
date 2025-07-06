# tf-aws-app-mongodb/aws

## Description

The directory for the AWS resources.

## Timing

Creation time: <20 minutes

Destruction time: ~15 minutes

## Troubleshooting & debugging

General troubleshooting guide information should be added here.

### cloud-init troubleshooting

* Cloud-init executes scripts in alphabetical order
    * For simplicity, label the created scripts with numbers according to execution order
    * Take note that this is related to how cloud-init works specifically and even the content type can also affect the execution order
* Note that you need sudo permissions
* Find the logs in `/var/log`, specifically `/var/log/cloud-init-output.log`
* Find the scripts in `/var/lib/cloud/instance/scripts`

### Forgot MongoDB admin password

__IMPORTANT: this messed up the DB set up. Probably the combination of using flags and not resetting from systemctl.__

In case you typoed or forgot your admin password, you can try the following. This should also not be possible in a Prod environment.

1. Stop MongoDB: `sudo systemctl stop mongod`
2. Restart MongoDB without auth: `sudo mongod --dbpath /var/lib/mongo --logpath /var/log/mongodb/mongod.log --fork --noauth`
3. Connect to MongoDB and set a new password

    ```shell
    mongosh

    use admin
    db.changeUserPassword("myUserAdmin", "newpassword")

    # or

    db.createUser({
    user: "myUserAdmin",
    pwd: "newpassword",
    roles: [ { role: "root", db: "admin" } ]
    })
    ```

4. Kill mongo: `sudo pkill mongod`
5. Restart MongoDB: `sudo systemctl start mongod`

### Enabling Authentication by default may cause issues

In your `mongod.conf`, if you set `authorization: enabled` before starting your MongoDB for the first time, your mongosh commands will fail without auth. However, there is a [localhost exception](https://www.mongodb.com/docs/v7.0/core/localhost-exception/).

For simplicity, enable it after creating the users.

If you forget to select which DB you're working with, e.g. `admin`, it will default to the `test` DB. Try to look up what you created in the `test` DB. Example, you may have created users in the `test` DB.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.90.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | ~> 2.3.6 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >= 3.4.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | 2.3.7 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 20.31 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.csp_admin_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.csp_admin_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.csp_admin_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.mongodb_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_internet_gateway.aws_igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_key_pair.aws_keypair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_main_route_table_association.aws_rta](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/main_route_table_association) | resource |
| [aws_route_table.aws_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_s3_bucket.mongdb_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.mongdb_bucket_pub_read_pol](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.mongdb_bucket_pub_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_object.backups_folder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_security_group.aws_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.additional_cidr_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.all_egress_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.my_ip_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.public_http_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vpc_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_subnet.aws_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.eks_subnet_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.eks_subnet_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_ami.amazon_linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.ec2_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.mongdb_bucket_public_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [cloudinit_config.instance_config](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [http_http.my_ip_address](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.my_ip_address_2](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_public_cidrs"></a> [additional\_public\_cidrs](#input\_additional\_public\_cidrs) | For dynamically adding more security groups to support additional CIDRs. Note the rule will be for all protocols and ports | `list(any)` | `null` | no |
| <a name="input_aws_availability_zone"></a> [aws\_availability\_zone](#input\_aws\_availability\_zone) | The availability zone within the provider region the resources will be running, e.g. eu-west-1a and ap-southeast-1b | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to use | `string` | `"eu-west-2"` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_eks_cluster_ver"></a> [eks\_cluster\_ver](#input\_eks\_cluster\_ver) | Version of the EKS cluster | `string` | `"1.31"` | no |
| <a name="input_eks_subnet_cidrs"></a> [eks\_subnet\_cidrs](#input\_eks\_subnet\_cidrs) | List of subnet CIDRs for EKS | `list(string)` | `[]` | no |
| <a name="input_environment_tag"></a> [environment\_tag](#input\_environment\_tag) | Environment tag applied to all resources | `string` | `"DEV"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | The name of the AWS key pair resource | `string` | n/a | yes |
| <a name="input_mongo_admin_password"></a> [mongo\_admin\_password](#input\_mongo\_admin\_password) | The password value of the MongoDB admin created at start | `string` | n/a | yes |
| <a name="input_mongo_admin_username"></a> [mongo\_admin\_username](#input\_mongo\_admin\_username) | The username value of the MongoDB admin created at start | `string` | n/a | yes |
| <a name="input_mongo_tasky_password"></a> [mongo\_tasky\_password](#input\_mongo\_tasky\_password) | The password value of the tasky user to access MongoDB | `string` | n/a | yes |
| <a name="input_mongo_tasky_username"></a> [mongo\_tasky\_username](#input\_mongo\_tasky\_username) | The username value of the tasky user to access MongoDB | `string` | n/a | yes |
| <a name="input_mongodb_instance_type"></a> [mongodb\_instance\_type](#input\_mongodb\_instance\_type) | The size used by the MongoDB instance | `string` | `"t2.medium"` | no |
| <a name="input_owner_tag"></a> [owner\_tag](#input\_owner\_tag) | Owner tag applied to all resources | `string` | n/a | yes |
| <a name="input_pri_key_file_path"></a> [pri\_key\_file\_path](#input\_pri\_key\_file\_path) | Path to the private key file on the system | `string` | n/a | yes |
| <a name="input_project_tag"></a> [project\_tag](#input\_project\_tag) | The tag for the name/id of the project the resource is associated with. Can also be used in the name of resources | `string` | n/a | yes |
| <a name="input_pub_key_file_path"></a> [pub\_key\_file\_path](#input\_pub\_key\_file\_path) | Path to the public key file on the system | `string` | n/a | yes |
| <a name="input_ssh_connection_user"></a> [ssh\_connection\_user](#input\_ssh\_connection\_user) | The default SSH user used for the connection, determined by the AMI selected | `string` | n/a | yes |
| <a name="input_subnet_cidr"></a> [subnet\_cidr](#input\_subnet\_cidr) | The cidr block range of IP addresses for the subnet | `string` | `"192.0.0.0/24"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The cidr block range of IP addresses for the virtual private cloud | `string` | `"192.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | The EKS cluster name for used as a data source |
| <a name="output_mongodb_private_ip"></a> [mongodb\_private\_ip](#output\_mongodb\_private\_ip) | Private IP of the MongoDB EC2 instance |
| <a name="output_mongodb_public_ip"></a> [mongodb\_public\_ip](#output\_mongodb\_public\_ip) | The public IP of the MongoDB instance |
| <a name="output_s3_backups_http_url"></a> [s3\_backups\_http\_url](#output\_s3\_backups\_http\_url) | HTTP URL to access the backups directory in S3 |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | Name of the S3 bucket |
<!-- END_TF_DOCS -->
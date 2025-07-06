# tf-aws-app-mongodb

## Description

This repository creates the following key resources:

1. EC2 instance running an outdated Amazon Linux 2 OS
    1. MongoDB configured to:
        1. Use authentication
        2. Create 2 users (admin & tasky)
    2. Have CSP admin instance profile attached
    3. Have a cron job to backup MongoDB and upload to S3 bucket
2. S3 bucket to store mongoDB backup
    1. Publicly accessible (read-only)
3. EKS cluster in same VPC as the EC2 instance
    1. Publicly accessible (Port 80 only)
4. Kubernetes (k8s) web application
    1. [Tasky pod](https://github.com/jeffthorne/tasky)
    2. Cluster-admin privilege attached

There are more resources, but the above are the key ones. They are deliberately not secure to facilitate security discussions, testing & scanning.

### Detailed requirements & security misconfigurations

1. VM:
    1. Old linux version: Amazon Linux 2
    2. CSP admin instance profile attached
2. MongoDB:
    1. Older version: 7
    2. Authentication configured
    3. Periodically runs dump and backup to S3 bucket
3. S3 bucket:
    1. Publicly accessible (read-only)
    2. Stores MongoDB backup
4. EKS:
    1. Same network as MongoDB VM
5. [Tasky App](https://github.com/jeffthorne/tasky):
    1. Deployed in EKS
    2. Connects to MongoDB
    3. Has text file with sensitive content
    4. Attached with cluster-admin privilege

### High-level file structure

```shell
.
├── tasky-main
└── terraform
    ├── aws
    │   ├── config
    │   ├── local_files
    │   └── templates
    └── k8s
```

* `task-main`: Included for reference. Not used in terraform code
* `terraform/aws`: Terraform code for setting up AWS infrastructure
* `terraform/k8s`: Terraform code for setting up K8s resources

## Interaction

* Using awscli to get kubeconfig: `aws eks update-kubeconfig --region <region> --name <eks-cluster-name>`
* Terraform outputs:
    * `tasky_app_url`: Access tasky app from browser
    * `s3_backups_http_url`: URL for backup, but only the "parent" directory
* Check for text file: `kubectl exec -n tasky $(kubectl get pods -n tasky -l app=tasky -o jsonpath='{.items[0].metadata.name}') -- ls /tmp/tasky/`
* Check if cluster-admin privilege is attached: `kubectl auth can-i '*' '*' --as=system:serviceaccount:tasky:default`

### Terraform commands

From parent directory, you can run the following:

```shell
# aws
terraform -chdir=terraform/aws init -upgrade
terraform -chdir=terraform/aws apply -var-file secret.tfvars

# K8s
terraform -chdir=terraform/k8s init -upgrade
terraform -chdir=terraform/k8s apply -var-file secret.tfvars

# Remember K8s should be destroyed first
terraform -chdir=terraform/k8s destroy -var-file secret.tfvars
terraform -chdir=terraform/aws destroy -var-file secret.tfvars
```

## Troubleshooting & debugging

General troubleshooting guide information should be added here. Individual directories have their own readmes and guides there.

### Running Kubernetes cluster required -> 2 Terraform working directories

* Unlike the rest of the K8s terraform resources, the `kubernetes_manifest` resource requires Terraform to check against a running K8s cluster __during terraform plan__
    * Quickest workaround was to separate the code into 2 working directories

### Misc troubleshooting commands

1. Network:
    1. Check where MongoDB is listening on: `sudo ss -tulnp | grep mongod`
    2. Check the networking values of tasky app: `nslookup <tasky_app_url without the http>`
2. Check Mongod settings: `mongosh --eval "db.adminCommand({ getCmdLineOpts: 1 })"`
3. Check Mongod systemctl status: `sudo systemctl status mongod`
4. Check Mongod process: `ps -eo user,pid,cmd | grep [m]ongo`
5. Check Cron jobs executed: `sudo grep CRON /var/log/cron`

## To-do list

List of improvements collated here for easier tracking.

* Combine the 2 terraform working directories into a single working directory
    * ~~Tested local exec~~: Requires running kubectl, and in that case, may as well use helm or K8s manifests directly instead of terraform
    * Is there a helm chart that could handle the problematic `kubernetes_manifest.alb_ingress_class_params` terraform resource?
* MongoDB script
    * Template MongoDB version
    * Template platform, i.e. Amazon Linux 2 or Amazon Linux 2023
    * Template which DB users get created in. Currently hardcoded to admin DB
    * Create users after enabling auth at start (May not be possible)
    * Copy and overwrite `mongod.conf` file instead of using `sudo grep`?
* Networking
    * Simplify creation of EKS subnets. Only the CIDR block & availability zone values are different
        * Dynamic creation?
        * Map type variable?
* Kubernetes
    * In `kubernetes_config_map.text_file` resource, make directory a variable instead of hardcoded file path. FYI local_files is in `.gitignore` file
    * Add metadata labels for `owner`, `environment` & `managed by`
* Misc
    * Decide if the code should specify that tasky app is being used or it should be generalised
        * Files like the `variables.tf` make specific reference to Tasky, while parts pf `k8s.tf` generalises it to `app`
    * Add variable support for cron code
    * Combine cron code with cloudinit?

### Security to-do list

* Trivy for IaC Scanning
    * IaC scanning: `trivy config --tf-vars terraform.tfvars,secret.tfvars . -o local_files/trivy_misconfig_findings.txt --severity CRITICAL,HIGH --skip-dirs "**/.terraform"`
    * Trivy file system/application scanning: `trivy fs . -o local_files/trivy_fs_findings.txt --severity CRITICAL,HIGH`
* AWS securityHub
* AWS secret manager for DB secrets
    * Cloudinit renders the sensitive data
* MongoDB app should be limited in which network interfaces it listens to
* Storage & management of the tf state file through TF cloud, S3, etc.

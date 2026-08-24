# tf-aws-app-mongodb

## Description

This repository creates the following key resources:

1. EC2 instance running an outdated Amazon Linux 2 OS
    1. MongoDB configured to:
        1. Use authentication
    2. Have CSP admin instance profile attached
    3. Have a cron job to backup MongoDB and upload to S3 bucket
2. S3 bucket to store mongoDB backup
    1. Publicly accessible (read-only)
3. General AWS
    1. Internet-facing AWS LB deployed as part of EKS Module
    2. Security group configured to ensure only K8s private network ingress is allowed into MongoDB subnet
4. Kubernetes (k8s) web application
    1. [Tasky pod](https://github.com/jeffthorne/tasky)
    2. Cluster-admin privilege attached
    3. Deployed in private subnet
    4. Ingress resource deployed

There are more resources, but the above are the key ones. They are deliberately not secure to facilitate security discussions, testing & scanning.

### Detailed requirements & security misconfigurations

1. VM:
    1. Old linux version: Amazon Linux 2
    2. CSP admin instance profile attached
    3. SSH exposed to internet
2. MongoDB:
    1. Older version: 7
    2. Authentication configured
    3. Periodically runs dump and backup to S3 bucket
3. S3 bucket:
    1. Publicly accessible (read-only)
    2. Stores MongoDB backup
4. [Tasky App](https://github.com/jeffthorne/tasky):
    1. Deployed in EKS via GHA pipeline
    2. Connects to MongoDB
    3. Has text file with sensitive content
    4. Attached with cluster-admin privilege
5. Infra deployment with HCP Terraform

### High-level file structure

```shell
.
├── tasky-main
├── k8s
└── terraform
    ├── config
    ├── local_files
    └── templates
```

* `tasky-main`: Included for reference. Not used
* `terraform`: Terraform code for setting up AWS infrastructure
* `k8s`: Yaml files for deployment of tasky

## Interaction

* Using awscli to get kubeconfig: `aws eks update-kubeconfig --region <region> --name <eks-cluster-name>`
* Terraform outputs:
    * `tasky_app_url`: Access tasky app from browser
    * `s3_backups_http_url`: URL for backup, but only the "parent" directory
* Check for text file: `kubectl exec -n tasky $(kubectl get pods -n tasky -l app=tasky -o jsonpath='{.items[0].metadata.name}') -- ls /tmp/tasky/`
* Check if cluster-admin privilege is attached: `kubectl auth can-i '*' '*' --as=system:serviceaccount:tasky:default`

## Troubleshooting & debugging

General troubleshooting guide information should be added here. Individual directories have their own readmes and guides there.

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

* MongoDB script
    * Template MongoDB version
    * Template platform, i.e. Amazon Linux 2 or Amazon Linux 2023
    * Template which DB users get created in. Currently hardcoded to admin DB
    * Create users after enabling auth at start (May not be possible)
    * Copy and overwrite `mongod.conf` file instead of using `sudo grep`?
* Misc
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

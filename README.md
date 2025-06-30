# tf-aws-app-mongodb

## Description

Repo code for setting up the following:

1. MongoDB (AWS EC2)
2. Web app that uses MongoDB (Helm? K8s)
3. All related AWS resources for the connection

Exercise for security testing.

### Project goals & requirements

1. VM: Old linux version
2. MongoDB:
    1. Old ver
    2. Credentials for app to use
    3. Privileged AWS IAM role
3. S3 bucket
    1. Configure for publicly read-access accessible (bad idea)
    2. Stores MongoDB backup
4. Script to do the backup of Mongodb
    1. Consider chronjob
5. Networking:
    1. MongoDB & App must be in same network; same VPC.
    2. Routing for public Access
6. App [Tasky App](https://github.com/jeffthorne/tasky):
    1. Deployed in K8s, aka EKS
    2. Add a txt file with sensitive data to container
    3. App must have privileged cluster admin capabilities (bad idea)

## Interaction

Quick notes and reference on how to begin interacting with the resources can be added here.

## Timing

Creation time: ? minutes

Destruction time: ? minutes

## Notes

Any miscellaneous points or interesting observations can be added here.

## Troubleshooting & debugging

General troubleshooting guide information should be added here.

### cloud-init troubleshooting

* Cloud-init executes scripts in alphabetical order
    * For simplicity, label the created scripts with numbers according to execution order
    * Take note that this is related to how cloud-init works specifically and even the content type can also affect the execution order
* Note that you need sudo permissions
* Find the logs in `/var/log`, specifically `/var/log/cloud-init-output.log`
* Find the scripts in `/var/lib/cloud/instance/scripts`

### Issue 1

Info and solutions (if any) for specific issues should have their own dedicated section.

## To-do list

* Get the K8s from the EKS TF aws code
* Restrict the ports needed to access the web app instead of all
* IAM roles for EKS
* EKS code
* S3 bucket

### Security stuff

* Trivy for IaC Scanning
* AWS securityHub
* AWS secret manager for DB secrets

## Requirements

To easily generate out the list of requirements, outputs, etc, use [terraform-docs](https://github.com/terraform-docs/terraform-docs) to create the documentation: `terraform-docs markdown --output-file README.md .`
...

# **Terraform Infrastructure Automation with Load Balancer**

We automate the creation of an AWS infrastructure using Terraform.  We create the following:

- A **VPC** (Virtual Private Cloud)
- **Subnets**
- **Security Groups**
- **EC2 Instances** running Apache Web Server
- An **Application Load Balancer (ALB)** for distributing traffic to EC2 instances

By using Github Workflows we can create and the destroy the infrastructure as needed.

## **Table of Contents**

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Usage](#usage)
- [CI/CD Workflow](#cicd-workflow)
- [Terraform Cloud](#why-do-we-need-terraform-cloud-or-another-backend-when-we-use-cicd)
- [Outputs](#outputs)
- [Destroying Resources](#destroying-resources)
## **Prerequisites**

1. **AWS Account** with credentials.
2. **Terraform** installed on your local machine.
3. **AWS CLI** installed and configured with your credentials.
4. **GitHub account** for GitHub Workflows.

### Install Terraform

Follow the instructions in the [official Terraform documentation](https://learn.hashicorp.com/tutorials/terraform/install-cli).

### Set up AWS CLI

Install and configure the AWS CLI with relevant AWS credentials:

```bash
aws configure
```

## **Setup**

1. Clone this repository to your local machine:
```bash
   git clone https://github.com/TheRoninski/terraformWorkshop.git
   cd terraformWorkshop
```

2. Initialize Terraform:
```bash
terraform init
```

3. Review the configuration files to ensure everything looks good (`main.tf`, `variables.tf`, `outputs.tf`, etc.).


## **Usage**

To apply the configuration and provision the infrastructure:

1. **Create the infrastructure**:
   ```bash
    terraform apply
    ```
	This will prompt you for confirmation. Type `yes` to proceed.

2. **Access the application**:  
    After the infrastructure is created, Terraform will output the **DNS name of the Load Balancer**. You can use this to access the Apache web servers running on your EC2 instances:
    ```
    http://<load-balancer-dns-name>
    ```


## **CI/CD Workflow**

This project includes GitHub Actions workflows to automate the deployment and destruction of infrastructure using Terraform.

### **Deploy Workflow**:

The **deploy** workflow provisions the infrastructure. It is triggered manually via GitHub Actions.

File: `.github/workflows/deploy.yml`

### **Destroy Workflow**:

The **destroy** workflow destroys all the resources created by Terraform. It is also triggered manually via GitHub Actions.

File: `.github/workflows/destroy.yml`


## **Why do we need Terraform Cloud (or another backend) when we use CI/CD?**

When using CI/CD, Terraform Cloud or another remote backend is essential for securely storing the Terraform **state** file. Here's why:

- **Persistence**: The Terraform state file is stored in a central location, ensuring it's accessible across different pipelines and users.
- **Collaboration**: Multiple users can safely interact with the same infrastructure without conflicting state changes.
- **State Locking**: Terraform Cloud ensures only one process can apply changes at a time, preventing conflicts and inconsistencies.
- **Security**: Sensitive data, like AWS credentials, is managed securely in a backend and not exposed in CI/CD logs.
- **Versioning**: Changes to the infrastructure are versioned, so you can roll back if something goes wrong.

In summary, using a backend like Terraform Cloud ensures **secure, reliable, and scalable management** of your infrastructure in a collaborative and automated way.

## **Outputs**

After running `terraform apply`, Terraform will output the **DNS name** of the Load Balancer:

```bash
lb_dns_name = "web-load-balancer-123456.us-east-1.elb.amazonaws.com"
```

You can use this DNS name to access the web servers hosted behind the load balancer.

## **Destroying Resources**

To destroy all resources that were created, run:

```bash
terraform destroy -auto-approve
```

This will remove the EC2 instances, VPC, subnets, security groups, load balancer, and any other resources created by Terraform.
---

### **License**

This project is licensed under the MIT License - see the LICENSE file for details.


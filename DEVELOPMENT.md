# Instructions for Setting Up Infrastructure with Terraform

## Prerequisites

- **Terraform** >= 1.3 installed: https://www.terraform.io/downloads.html 
- Access to **AWS configured**
  - Make sure you have enough permissions to create and manage resources in the AWS account. 
  - **To do so, check the IAM policies attached to your user and the ones needed to run this code.**

## Getting started

**1. Clone the repository:**

```bash
git clone https://github.com/lrasata/infra-s3-image-moderator.git
cd infra-s3-image-moderator
```

**2. Initialize Terraform:**

````bash
terraform init
````

**3. Format configuration:**

````bash
terraform fmt
````

**4. Validate configuration:**

````bash
terraform validate
````

**5. Choose your environment and plan/apply:**

This project uses .tfvars files to handle multiple environments (e.g., dev, staging, prod).

**Example .tfvars files:**

````text
# staging.tfvars
region                    = "eu-central-1"
environment               = "staging"

# existing bucket
s3_bucket_name            = "staging-trip-planner-app-media-uploads-bucket"
s3_bucket_arn             = "arn:aws:s3:::staging-trip-planner-app-media-uploads-bucket"

s3_quarantine_bucket_name = "quarantine-bucket"
admin_email               = "test@test.com"
````


Plan and apply for a specific environment:

````text
terraform plan -var-file="staging.tfvars"
terraform apply -var-file="staging.tfvars"
````

## Usage
### Running the image moderation lambda function
Event Bridge is used to trigger the image moderation lambda function every 24h.

For testing purposes, you can manually trigger the lambda function `staging-image-moderator-lambda` by
using AWS admin console or CLI with the following command:

````bash
aws lambda invoke --function-name staging-image-moderator-lambda --payload "{}"
````

### Moving images from src bucket to quarantine bucket
Event Bridge is used to trigger the lambda function which moves flagged images to quarantine bucket every 24h.

For testing purposes, you can manually trigger the lambda function `staging-move-to-quarantine-lambda` by
using AWS admin console or CLI with the following command:

````bash
aws lambda invoke --function-name staging-move-to-quarantine-lambda --payload "{}"
````


## Notes

- Always review the output of terraform plan before applying changes.
- Keep .terraform.lock.hcl committed for consistent provider versions.

## Destroying Infrastructure

To tear down all resources managed by this project:

````bash
terraform destroy -var-file="staging.tfvars"
````

Replace `staging.tfvars` with the appropriate tfvars environment file.
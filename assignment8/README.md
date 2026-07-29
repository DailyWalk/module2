# Deploying a Sample Node.js App to AWS Elastic Beanstalk with Terraform

This folder contains everything needed to deploy a minimal "Hello World"
Node.js/Express application to AWS Elastic Beanstalk using Terraform.

## Folder structure

```
eb-nodejs-terraform/
├── main.tf          # Core infrastructure: S3, IAM, EB application/environment
├── variables.tf      # Input variables (region, app name, instance type, etc.)
├── outputs.tf         # Outputs (app URL, environment name, etc.)
├── app/
│   ├── app.js         # Sample Express "Hello World" app
│   └── package.json   # Node.js dependencies
└── README.md
```

## Prerequisites

1. **AWS account** with permissions to create IAM roles, S3 buckets, and
   Elastic Beanstalk resources.
2. **AWS CLI configured** with credentials (`aws configure`), or environment
   variables `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` set.
3. **Terraform** >= 1.3 installed ([download](https://developer.hashicorp.com/terraform/install)).
4. Confirm the `solution_stack_name` in `variables.tf` is still current for
   your region by running:
   ```
   aws elasticbeanstalk list-available-solution-stacks --query "SolutionStacks[?contains(@, 'Node.js')]"
   ```
   Update the default value in `variables.tf` if a newer stack is listed.

## Deployment steps

```bash
cd eb-nodejs-terraform

# 1. Initialize Terraform (downloads AWS + archive providers)
terraform init

# 2. Review the execution plan
terraform plan

# 3. Apply — creates S3 bucket, IAM roles, EB app, EB environment
terraform apply
```

Type `yes` when prompted. Initial environment creation typically takes
**5–10 minutes** since AWS provisions an EC2 instance, security group, and
(depending on config) a load balancer.

## What gets created

| Resource | Purpose |
|---|---|
| `aws_s3_bucket` | Stores the zipped application source bundle |
| `aws_iam_role` (EC2) | Instance role attached to the EB EC2 instance(s) |
| `aws_iam_role` (service) | Role Elastic Beanstalk uses to manage resources on your behalf |
| `aws_elastic_beanstalk_application` | Logical container for app versions |
| `aws_elastic_beanstalk_application_version` | Points EB to the S3 zip to deploy |
| `aws_elastic_beanstalk_environment` | The actual running environment (EC2 instance, health checks, URL) |

## Verifying the deployment / suggested screenshots

Once `terraform apply` finishes, it prints an `environment_url` output.

1. **Terraform apply output** — terminal showing `Apply complete!` and the
   `environment_url`, `environment_name` outputs.
2. **AWS Console → Elastic Beanstalk → Environments** — showing the
   environment with a green "Health: Ok" status.
3. **AWS Console → Elastic Beanstalk → Environment → Dashboard** — showing
   the application version, platform, and health details.
4. **Browser window** — navigate to the `environment_url` (e.g.
   `http://eb-sample-nodejs-env.xxxxxxxxxx.us-east-1.elasticbeanstalk.com`)
   showing the "🚀 Hello from AWS Elastic Beanstalk!" page rendered live.
5. **AWS Console → S3** — showing the bucket with the uploaded `app.zip`
   source bundle.

You can grab the live URL any time after a successful apply with:
```bash
terraform output environment_url
```

## Cleaning up

To avoid ongoing charges, destroy all resources when done:
```bash
terraform destroy
```

## Notes

- This configuration uses `EnvironmentType = SingleInstance` (no load
  balancer) to keep the demo low-cost and within AWS Free Tier eligibility
  (`t3.micro`). Remove that setting block if you want a load-balanced,
  auto-scaled environment instead.
- The application zip is rebuilt automatically whenever files under `app/`
  change, thanks to the `archive_file` data source's MD5-based versioning —
  just re-run `terraform apply` to deploy updates.

# Deployment Guide

## Prerequisites

- Terraform `>= 1.8.5`
- AWS CLI v2 authenticated (do not use `--profile`; rely on environment/SSO/default credentials)
- `kubectl`
- `helm` v3
- Access to:
  - Existing VPC and private subnets
  - S3 bucket + DynamoDB table for Terraform state
  - IAM permissions to create EKS, IAM, EC2 tags, SQS, EventBridge

## Step 1: Prepare environment files

For the selected environment (`dev`, `stage`, `prod`):

1. Copy examples to active tfvars:

```powershell
Copy-Item envs/dev/infra/terraform.tfvars.example envs/dev/infra/terraform.tfvars
Copy-Item envs/dev/addons/terraform.tfvars.example envs/dev/addons/terraform.tfvars
```

2. Update values:
- VPC and subnet IDs
- backend state parameters (`terraform init -backend-config=...`)
- versions/tags/capacity limits

## Step 2: Deploy infra stack

```powershell
terraform -chdir=envs/dev/infra init -backend-config="bucket=<state-bucket>" -backend-config="key=karpenter/dev/infra/terraform.tfstate" -backend-config="region=us-east-1" -backend-config="dynamodb_table=<lock-table>"
terraform -chdir=envs/dev/infra plan
terraform -chdir=envs/dev/infra apply
```

## Step 3: Deploy addons stack (Karpenter + interruptions)

```powershell
terraform -chdir=envs/dev/addons init -backend-config="bucket=<state-bucket>" -backend-config="key=karpenter/dev/addons/terraform.tfstate" -backend-config="region=us-east-1" -backend-config="dynamodb_table=<lock-table>"
terraform -chdir=envs/dev/addons plan
terraform -chdir=envs/dev/addons apply
```

## Step 4: Configure kubeconfig

```powershell
$cluster = terraform -chdir=envs/dev/infra output -raw cluster_name
$region  = terraform -chdir=envs/dev/infra output -raw aws_region
aws eks update-kubeconfig --name $cluster --region $region
```

## Step 5: Render and apply NodeClass/NodePools

```powershell
./scripts/render-manifests.ps1 -Environment dev -UseTerraformOutputs
kubectl apply -f manifests/rendered/dev
```

## Step 6: Optional smoke tests

```powershell
./scripts/smoke-test.ps1
```

## One-command helper

```powershell
./scripts/deploy.ps1 -Environment dev
```

## Post-deploy validation

```powershell
./scripts/validate.ps1 -Environment dev
```
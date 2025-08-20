# TripRadar Terraform

This directory contains the Terraform IaC for TripRadar Azure infrastructure.

## Structure

infra/terraform/
- stacks/app/        # Reusable application stack (RG, Log Analytics, App Insights, ACR, KV, DB, Redis, Container Apps)
- environments/
  - dev/
    - terraform.tfvars
  - prod/
    - terraform.tfvars

## Usage

Prereqs: Terraform >= 1.6, Azure subscription, Azure CLI logged in (or Service Principal in CI).

Initialize and plan an environment (local machine):

```bash
cd infra/terraform/stacks/app
terraform init
terraform plan -var-file=../../environments/dev/terraform.tfvars
```

Apply:
```bash
terraform apply -var-file=../../environments/dev/terraform.tfvars
```

> NOTE: Remote state backend (Azure Storage) is recommended. You can pass backend config at init time, e.g.:
> `terraform init -backend-config="resource_group_name=..." -backend-config="storage_account_name=..." -backend-config="container_name=tfstate" -backend-config="key=tripradar-dev.tfstate"`

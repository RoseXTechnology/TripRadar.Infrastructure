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

---

## Validate changes for dev

From `infra/terraform/stacks/app/`:

```bash
# Format check
terraform fmt -check -recursive

# Init (uses local backend unless you pass -backend-config)
terraform init

# Validate
terraform validate

# Plan against dev vars
terraform plan -var-file=../../environments/dev/terraform.tfvars
```

---

## tfvars examples (Libby)

Libby Container App is optional and disabled by default. To enable in an environment tfvars:

```hcl
# Libby (optional)
enable_libby           = true
libby_port             = 8080
libby_ingress_external = false # set true only if public ingress is needed
libby_min_replicas     = 1
libby_max_replicas     = 1

# ACR (enable if using private images)
enable_acr = true
acr_name   = "<your-acr-name>" # without .azurecr.io

# Key Vault (recommended for secrets)
enable_key_vault = true
# key_vault_name = null # use default naming or set explicitly
```

Images are provided at apply time via TF_VARs (set by CI), e.g. `TF_VAR_api_image`, `TF_VAR_jobs_image`, `TF_VAR_libby_image`.

---

## End-to-end CI example (build images → apply infra)

This example runs in an app repo (e.g., TripRadar.Server) and:
1) Builds and pushes API and Jobs images to ACR using the reusable workflow in this repo.
2) Triggers the infra workflow here to apply with produced image tags.

```yaml
name: Build, Push, and Deploy Infra (dev)

on:
  workflow_dispatch: {}
  push:
    branches: [ dev ]
    paths:
      - 'TripRadar.Server.API/**'
      - 'TripRadar.Server.Jobs.API/**'
      - '.github/workflows/**'

jobs:
  build-matrix:
    strategy:
      matrix:
        service: [ api, jobs ]
    uses: RoseXTechnology/TripRadar.Infrastructure/.github/workflows/reusable-build-push.yml@dev
    with:
      acr_name: ${{ vars.ACR_NAME }}
      repository: ${{ matrix.service == 'api' && 'tripradar/api' || 'tripradar/jobs' }}
      context: ${{ matrix.service == 'api' && './TripRadar.Server.API' || './TripRadar.Server.Jobs.API' }}
      dockerfile: ${{ matrix.service == 'api' && './TripRadar.Server.API/Dockerfile' || './TripRadar.Server.Jobs.API/Dockerfile' }}
      tag: ${{ github.sha }}
    secrets:
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

  deploy-infra:
    needs: build-matrix
    runs-on: ubuntu-latest
    steps:
      - name: Derive image refs
        id: refs
        run: |
          # Assuming both matrix runs produced same tag (commit SHA)
          echo "api= ${{ vars.ACR_LOGIN_SERVER }}/tripradar/api:${{ github.sha }}" >> $GITHUB_OUTPUT
          echo "jobs=${{ vars.ACR_LOGIN_SERVER }}/tripradar/jobs:${{ github.sha }}" >> $GITHUB_OUTPUT

      - name: Trigger Infra Workflow (TF Apply)
        uses: benc-uk/workflow-dispatch@v1
        with:
          workflow: Infrastructure - Terraform
          repo: RoseXTechnology/TripRadar.Infrastructure
          ref: dev
          token: ${{ secrets.INFRA_REPO_PAT }}
          inputs: |
            {
              "environment": "dev",
              "api_image": "${{ steps.refs.outputs.api }}",
              "jobs_image": "${{ steps.refs.outputs.jobs }}"
            }
```

Notes:
- Set repository variables in the app repo:
  - `ACR_NAME` (e.g., `myacr`)
  - `ACR_LOGIN_SERVER` (e.g., `myacr.azurecr.io`)
- `INFRA_REPO_PAT` must have `repo` scope to dispatch workflows to the infra repo.
- To include Libby, build it similarly and pass `libby_image` in the `inputs` payload.


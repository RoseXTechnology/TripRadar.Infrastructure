# TripRadar Infrastructure (Terraform)

This folder provisions Azure resources for TripRadar using Terraform. It includes Azure Container Apps (ACA), ACR, optional Log Analytics and Application Insights, with advanced options via AzAPI.

## Layout
- `stacks/app/`
  - `backend.tf`: Remote state backend `azurerm`.
  - `main.tf`: Resource Group, optional Log Analytics, App Insights, Container Apps Environment, ACR. Tags include `"azd-env-name"`.
  - `container_apps.tf`: API, Jobs, Libby container apps via module; tags include `"azd-service-name"`.
  - `variables*.tf`: Feature toggles (e.g., `enable_acr`, `enable_container_app_environment`, `enable_libby`, `enable_cors`, `enable_http_scaling_patch`).
  - `azapi_patches.tf`: AzAPI patches for CORS and HTTP concurrency scaling.
  - `outputs.tf`: AZD-compatible outputs (e.g., `RESOURCE_GROUP_ID`, `AZURE_CONTAINER_REGISTRY_ENDPOINT`).
  - `versions.tf`: Providers (AzureRM, AzAPI).
- `modules/container_app/`: Reusable module for Container Apps (identity, ingress, probes, env/secrets, scale).
- `environments/`: Env-specific `terraform.tfvars` for `dev/` and `prod/`.
- `.github/workflows/`:
  - `infra-terraform.yml`: CI for fmt/validate/plan on PR; apply on `dev`/`main` pushes; manual dispatch supported.
  - `reusable-build-push.yml`: Build and push Docker images to ACR; outputs the full image reference.

## Prerequisites
- Azure subscription and permissions to create resources.
- Remote state storage (one-time):
  - Resource Group (e.g., `rg-tfstate`)
  - Storage Account (e.g., `sttfstate123`)
  - Blob Container (e.g., `tfstate`)
- GitHub OIDC setup (Service Principal/Federated Credential) for `azure/login@v2`.
- GitHub repo secrets:
  - `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
  - `TFSTATE_RG`, `TFSTATE_SA`, `TFSTATE_CONTAINER`

## Configure environment (`environments/dev/terraform.tfvars`)
Example:
```hcl
project      = "tripradar"
environment  = "dev"
location     = "northeurope"

# Registry
enable_acr = true
acr_name   = "tripradardevacr"

# Container Apps Environment
enable_container_app_environment = true

# Images (set after you push)
api_image   = null
jobs_image  = null
enable_libby = false
libby_image  = null

# Optional features
enable_cors               = false
cors_allowed_origins      = ["https://localhost:5001"]
enable_http_scaling_patch = false
```

## Local workflow (Windows/PowerShell)
Navigate to `infra/terraform/stacks/app/` and run:

1) Init remote backend:
```powershell
terraform init -backend-config="resource_group_name=$env:TFSTATE_RG" `
  -backend-config="storage_account_name=$env:TFSTATE_SA" `
  -backend-config="container_name=$env:TFSTATE_CONTAINER" `
  -backend-config="key=tripradar-dev.tfstate"
```

2) Validate and plan:
```powershell
terraform validate
terraform plan -var-file=../../environments/dev/terraform.tfvars
```

3) Apply:
```powershell
terraform apply -var-file=../../environments/dev/terraform.tfvars
```

## Build and push TripRadar.Server image (from Windows)
Location: `C:\Education\TripRadar.Server`

Option A — Local Docker + ACR:
```powershell
az login
az account set --subscription "<SUBSCRIPTION_ID>"
az acr login -n tripradardevacr

# Build and push API image
$tag = "dev-$(git rev-parse --short HEAD)"  # or any tag you prefer
$img = "tripradardevacr.azurecr.io/tripradar/api:$tag"
docker build -t $img -f .\Dockerfile .
docker push $img
```
Then set the image for Terraform:
- Edit `environments/dev/terraform.tfvars` → `api_image = "tripradardevacr.azurecr.io/tripradar/api:<tag>"`
  or
- Export for one run: `setx TF_VAR_api_image <full-image-ref>` (new shells only)

Option B — GitHub Actions reusable workflow:
- Create a workflow in your app repo that calls `.github/workflows/reusable-build-push.yml` with:
  - `acr_name: tripradardevacr`
  - `repository: tripradar/api`
  - `context: ./server/TripRadar.Server.API` (adjust path)
  - `dockerfile: ./server/TripRadar.Server.API/Dockerfile`
- Use the output `image` value as `api_image` for Terraform (via tfvars or `TF_VAR_api_image`).

## CI/CD with provided workflows
- Pull Requests (changes in `infra/terraform/**`):
  - `infra-terraform.yml` runs `fmt`, `init`, `validate`, `plan` against `dev`.
- Push to `dev` branch:
  - `infra-terraform.yml` runs `init` and `apply` using `../../environments/dev/terraform.tfvars`.
- Push to `main` branch:
  - `infra-terraform.yml` runs `init` and `apply` using `../../environments/prod/terraform.tfvars`.
- Manual dispatch:
  - Trigger `Infrastructure - Terraform` → select `environment`, optionally pass `api_image`, `jobs_image`, `libby_image`.

## Optional features
- CORS via AzAPI (`stacks/app/azapi_patches.tf`):
  - Enable with `enable_cors = true` and set `cors_allowed_origins`.
  - Requires external ingress for target app(s).
- HTTP concurrency scaling via AzAPI:
  - Enable with `enable_http_scaling_patch = true`.
  - Uses `api_concurrent_requests` from variables for KEDA HTTP concurrency rule.

## Tips
- `acr_name` must be lowercase alphanumeric (Azure rule).
- Ensure `enable_acr = true` if you want to host images in ACR.
- `RESOURCE_GROUP_ID` and `AZURE_CONTAINER_REGISTRY_ENDPOINT` outputs are provided for AZD-style consumers.
- If using Redis, ensure no deprecated flags are set against your chosen `azurerm` provider version.

## End-to-end steps (dev)
1) Provision infra: run Terraform apply locally or push to `dev` to trigger CI apply.
2) Build & push your API image to ACR (local or GitHub Actions).
3) Set `api_image` (and others if needed) in `dev/terraform.tfvars`.
4) Re-apply Terraform to update the Container App image.
5) Validate ACA app ingress FQDN and logs; confirm CORS/scaling if enabled.

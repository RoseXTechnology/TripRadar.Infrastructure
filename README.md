# TripRadar Infrastructure

Infrastructure as Code for TripRadar using Terraform and Azure.

## Project Structure

```
TripRadar.Infrastructure/
├── infra/
│   └── terraform/
│       ├── environments/          # Environment-specific configurations
│       │   ├── dev/
│       │   │   ├── app/          # Development environment
│       │   │   └── terraform.tfvars
│       │   ├── staging/          # Staging environment
│       │   │   ├── app/
│       │   │   └── terraform.tfvars
│       │   └── prod/             # Production environment
│       │       ├── app/
│       │       └── terraform.tfvars
│       ├── modules/              # Reusable Terraform modules
│       │   └── container_app/
│       └── stacks/               # Infrastructure stacks
│           └── app/              # Main application stack
├── .github/
│   └── workflows/                # GitHub Actions CI/CD
│       ├── build-push.yml        # Build and push container images
│       ├── core-pipeline.yml     # Quality & security checks
│       └── infra-terraform.yml   # Infrastructure deployment
├── postman/                      # API testing collections
├── templates/                    # Configuration templates
└── docker/                       # Docker management scripts
```

## Quick Start

### Prerequisites

1. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Terraform** 1.6.0+ - [Install Terraform](https://www.terraform.io/downloads)
3. **Azure Subscription** with appropriate permissions

### Authentication

```bash
# Login to Azure
az login
az account set --subscription "your-subscription-id"
```

### Development Environment Setup

```bash
# Navigate to development environment
cd infra/terraform/environments/dev/app

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="../../../environments/dev/terraform.tfvars"

# Apply changes
terraform apply -var-file="../../../environments/dev/terraform.tfvars"
```

## Environments

- **Development** (`dev`) - Public access, minimal security
- **Staging** (`staging`) - Private access, production-like setup
- **Production** (`prod`) - Private access, full security and scaling

## Deployment

See [TERRAFORM_COMMANDS.md](TERRAFORM_COMMANDS.md) for complete Terraform command reference.

### Automated Deployment

Use GitHub Actions workflows for automated deployment:

1. **Quality & Security** - `core-pipeline.yml`
2. **Build & Push** - `build-push.yml`
3. **Infrastructure** - `infra-terraform.yml`

### Manual Deployment

For manual deployments or local development:

```bash
# Development
cd infra/terraform/environments/dev/app
terraform apply -auto-approve -var-file="../../../environments/dev/terraform.tfvars"

# Staging
cd ../../../staging/app
terraform apply -auto-approve -var-file="../../../environments/staging/terraform.tfvars"

# Production (review plan first)
cd ../../../prod/app
terraform plan -var-file="../../../environments/prod/terraform.tfvars"
terraform apply -var-file="../../../environments/prod/terraform.tfvars"
```

## Architecture

### Infrastructure Components

- **Azure Container Apps** - Main application hosting
- **Azure Container Registry** - Private container images
- **Azure Key Vault** - Secrets management
- **PostgreSQL Flexible Server** - Database
- **Azure Front Door** - CDN and WAF (production)
- **Azure Monitor** - Logging and monitoring
- **Azure Event Hubs** - Message streaming (optional)

### Security Features

- **Managed Identities** - Secure service-to-service communication
- **Private Endpoints** - Secure network access
- **Azure Front Door WAF** - Web application firewall
- **RBAC** - Role-based access control
- **TLS/SSL** - End-to-end encryption

## Configuration

### Environment Variables

Configure your deployment using `.tfvars` files:

- `dev/terraform.tfvars` - Development settings
- `staging/terraform.tfvars` - Staging settings
- `prod/terraform.tfvars` - Production settings

### Custom Domains

To configure custom domains:

1. Update `api_custom_domain` in your `.tfvars` file
2. Add DNS records as shown in Terraform outputs
3. Run `terraform apply`

## Monitoring & Troubleshooting

### Logs

```bash
# View application logs
az containerapp logs show --name tripradar-dev-api --resource-group tripradar-dev-rg

# View Terraform state
terraform show
```

### Common Issues

1. **Timeout Errors** - Use phased deployment approach
2. **State Lock** - Run `terraform force-unlock LOCK_ID`
3. **Import Resources** - Use `terraform import` for existing resources

## Contributing

1. Test changes in development environment first
2. Use conventional commits for PRs
3. Update documentation for infrastructure changes
4. Run `terraform validate` and `terraform plan` before committing

## Support

- [Terraform Documentation](https://www.terraform.io/docs)
- [Azure Container Apps](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Azure Resource Manager](https://docs.microsoft.com/en-us/azure/azure-resource-manager/)

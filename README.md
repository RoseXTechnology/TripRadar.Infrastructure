# TripRadar Infrastructure

A comprehensive, production-ready Azure infrastructure deployment using Bicep templates for the TripRadar multi-application ecosystem.

## 🏗️ Architecture Overview

This infrastructure supports containerized applications with the following components:

### Core Services
- **Main API**: Primary TripRadar application API
- **Jobs API**: Background job processing service
- **Database**: PostgreSQL database with high availability
- **Caching**: Redis Cache for performance optimization

### Azure Services
- **Azure Container Apps**: Serverless container hosting
- **Azure Container Registry**: Private container image storage
- **Azure Database for PostgreSQL**: Managed database service
- **Azure Cache for Redis**: Managed Redis service
- **Azure Key Vault**: Secrets and configuration management
- **Azure Storage Account**: Blob storage for artifacts and backups
- **Azure Monitor & Application Insights**: Monitoring and observability
- **Virtual Network**: Secure network isolation with private endpoints

## 📁 Project Structure

```
TripRadar.Infrastructure/
├── bicep/                          # Infrastructure as Code
│   ├── modules/                    # Reusable Bicep modules
│   │   ├── networking/             # VNet, subnets, NSGs
│   │   ├── security/               # Key Vault, managed identity
│   │   ├── storage/                # Storage account, Redis
│   │   ├── database/               # PostgreSQL configuration
│   │   ├── containers/             # ACR, Container Apps environment
│   │   ├── monitoring/             # Application Insights, Log Analytics
│   │   └── applications/           # TripRadar application definitions
│   ├── parameters/                 # Environment-specific parameters
│   │   ├── dev.bicepparam         # Development environment
│   │   ├── staging.bicepparam     # Staging environment
│   │   └── prod.bicepparam        # Production environment
│   ├── main.bicep                 # Main orchestration template
│   └── deploy.bicep               # Subscription-level deployment
├── .github/workflows/             # CI/CD pipelines
│   ├── infrastructure-deploy.yml  # Infrastructure deployment
│   └── app-deploy.yml             # Application deployment
├── scripts/                       # Deployment scripts
│   ├── deploy.ps1                # PowerShell deployment script
│   ├── deploy.sh                 # Bash deployment script
│   └── cleanup.ps1               # Resource cleanup script
├── docker/                       # Docker utility scripts
└── postman/                      # API testing collections
```

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Azure Subscription** with appropriate permissions
3. **Git** for repository management
4. **PowerShell 7+** or **Bash** for running scripts

### 1. Clone Repository

```bash
git clone <repository-url>
cd TripRadar.Infrastructure
```

### 2. Login to Azure

```bash
az login
az account set --subscription "your-subscription-id"
```

### 3. Get Required Information

You'll need:
- **Key Vault Admin Object ID**: Your Azure AD user/service principal object ID
- **PostgreSQL Admin Credentials**: Username and password for database

Get your object ID:
```bash
az ad signed-in-user show --query id -o tsv
```

### 4. Deploy Infrastructure

#### Using PowerShell Script (Recommended)

```powershell
# Development environment
.\scripts\deploy.ps1 -Environment dev -KeyVaultAdminObjectId "your-object-id"

# Production environment with confirmation
.\scripts\deploy.ps1 -Environment prod -KeyVaultAdminObjectId "your-object-id"

# What-If deployment (preview changes)
.\scripts\deploy.ps1 -Environment dev -KeyVaultAdminObjectId "your-object-id" -WhatIf
```

#### Using Bash Script

```bash
# Development environment
./scripts/deploy.sh -e dev -k "your-object-id"

# Production environment
./scripts/deploy.sh -e prod -k "your-object-id"

# What-If deployment
./scripts/deploy.sh -e dev -k "your-object-id" -w
```

#### Using Azure CLI Directly

```bash
az deployment sub create \
  --name "tripradar-infra-dev" \
  --location "North Europe" \
  --template-file bicep/deploy.bicep \
  --parameters bicep/parameters/dev.bicepparam \
  --parameters keyVaultAdminObjectId="your-object-id" \
  --parameters postgresqlAdminUsername="admin_user" \
  --parameters postgresqlAdminPassword="secure_password"
```

## 🌍 Environment Configuration

### Development Environment
- **Cost-optimized** resource sizes
- **Basic** SKUs where appropriate
- **Private endpoints disabled** (for cost savings)
- **Single-region** deployment
- **Short retention** periods

### Staging Environment  
- **Mid-tier** resource sizes
- **Standard** SKUs for testing production features
- **Private endpoints enabled** (to test production configuration)
- **Extended retention** for troubleshooting

### Production Environment
- **High-performance** resource sizes
- **Premium** SKUs with high availability
- **Private endpoints enabled** for security
- **Multi-region** deployment with geo-redundancy
- **Extended retention** and backup policies
- **Auto-scaling** enabled
- **Zone-redundancy** where available

## 🔐 Security Features

### Network Security
- **Virtual Network** with dedicated subnets
- **Network Security Groups** with least-privilege rules
- **Private Endpoints** for PaaS services (production)
- **Private DNS Zones** for internal name resolution

### Identity & Access
- **Managed Identity** for service-to-service authentication
- **Key Vault** for secrets and configuration management
- **RBAC** with principle of least privilege
- **Azure AD integration**

### Data Protection
- **TLS 1.2 minimum** for all connections
- **Encryption at rest** for all storage services
- **Backup retention** policies
- **Soft delete** enabled for Key Vault

## 📊 Monitoring & Observability

### Application Insights
- **Performance monitoring**
- **Error tracking and alerting**
- **Usage analytics**
- **Custom dashboards**

### Log Analytics
- **Centralized logging**
- **Query and analysis**
- **Long-term retention**
- **Security event monitoring**

### Alerting
- **High error rate alerts**
- **Performance degradation alerts**
- **Resource utilization alerts**
- **Security event alerts**

## 🚀 CI/CD Integration

### GitHub Actions Workflows

#### Infrastructure Deployment
- **Automatic validation** on pull requests
- **Security scanning** with Checkov
- **Environment-specific deployments**
- **Production safety controls**

#### Application Deployment
- **Container image building** and scanning
- **Multi-environment deployment**
- **Blue-green deployment** for production
- **Automated rollback** capabilities

### Required Secrets

Configure these secrets in your GitHub repository:

```
AZURE_CREDENTIALS           # Service principal credentials
KEYVAULT_ADMIN_OBJECT_ID   # Key Vault admin object ID
POSTGRESQL_ADMIN_USERNAME  # Database admin username
POSTGRESQL_ADMIN_PASSWORD  # Database admin password
DOCKER_HUB_USERNAME        # Docker Hub username
DOCKER_HUB_TOKEN          # Docker Hub access token
```

## 🔧 Configuration Management

### Key Vault Secrets
The infrastructure automatically creates these secrets:
- `DatabaseConnectionString` - PostgreSQL connection
- `RedisConnectionString` - Redis cache connection
- `StorageConnectionString` - Azure Storage connection
- `ApplicationInsights-ConnectionString` - App Insights connection

### Application Configuration
Applications receive configuration through:
- **Environment variables** from Key Vault
- **Dapr components** for Redis and secrets
- **JSON configuration** from storage containers

## 📦 Container Management

### Azure Container Registry
- **Private container registry**
- **Vulnerability scanning** (Premium tier)
- **Geo-replication** (production)
- **Content trust** and quarantine policies

### Container Apps
- **Serverless container hosting**
- **Auto-scaling** based on HTTP requests and custom metrics
- **Traffic splitting** for blue-green deployments
- **Built-in load balancing**

## 💾 Data Management

### PostgreSQL Database
- **Flexible Server** with high availability
- **Automated backups** with point-in-time recovery
- **Private networking** with VNet integration
- **Read replicas** for production scaling

### Redis Cache
- **High availability** configuration
- **Persistence** enabled
- **SSL-only** connections
- **Memory optimization** policies

## 🧪 Testing & Validation

### Infrastructure Testing
```bash
# Validate templates
az deployment sub validate --template-file bicep/deploy.bicep --parameters bicep/parameters/dev.bicepparam

# What-if deployment
az deployment sub what-if --template-file bicep/deploy.bicep --parameters bicep/parameters/dev.bicepparam
```

### Application Testing
```bash
# Health check endpoints
curl https://your-app.azurecontainerapps.io/health
curl https://your-app.azurecontainerapps.io/ready
```

## 🧹 Cleanup

### Remove Resources

```powershell
# Clean up development environment
.\scripts\cleanup.ps1 -Environment dev -DeleteResourceGroup -WhatIf

# Clean up with confirmation
.\scripts\cleanup.ps1 -Environment dev -DeleteResourceGroup
```

### Cost Management
- **Resource tagging** for cost allocation
- **Auto-shutdown** policies for development
- **Reserved instances** recommendations for production
- **Cost alerts** and budgets

## 🔧 Troubleshooting

### Common Issues

1. **Deployment Timeouts**
   - Check Azure service health
   - Verify resource quotas
   - Review deployment logs in Azure portal

2. **Permission Errors**
   - Verify Azure RBAC permissions
   - Check service principal configuration
   - Validate Key Vault access policies

3. **Network Connectivity**
   - Verify NSG rules
   - Check private endpoint configuration
   - Review DNS resolution

4. **Application Startup Issues**
   - Check container logs in Container Apps
   - Verify Key Vault secrets access
   - Review application configuration

### Useful Commands

```bash
# Check deployment status
az deployment sub show --name "deployment-name"

# View container app logs
az containerapp logs show --name "app-name" --resource-group "rg-name"

# List Key Vault secrets
az keyvault secret list --vault-name "vault-name"

# Check resource health
az resource list --resource-group "rg-name" --query "[].{name:name,type:type,location:location}"
```

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch
3. **Test** changes in development environment
4. **Submit** pull request with detailed description
5. **Ensure** all CI/CD checks pass

## 📋 Maintenance

### Regular Tasks
- **Update** container images regularly
- **Review** and rotate secrets
- **Monitor** resource utilization and costs
- **Update** Bicep templates and dependencies
- **Review** security alerts and recommendations

### Backup Strategy
- **Automated database backups** with retention policies
- **Configuration backup** in version control
- **Disaster recovery** testing procedures
- **Documentation** of recovery procedures

## 📞 Support

For support and questions:
- **Create an issue** in this repository
- **Check documentation** in the `/docs` folder
- **Review logs** in Application Insights
- **Contact** the DevOps team

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**⚠️ Important Notes:**
- Always test in development before deploying to production
- Review costs regularly to avoid unexpected charges  
- Keep secrets secure and rotate them regularly
- Monitor security alerts and apply updates promptly
- Document any customizations or changes made to the infrastructure
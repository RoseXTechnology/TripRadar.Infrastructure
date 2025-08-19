# TripRadar Infrastructure

A comprehensive, production-ready Azure infrastructure deployment using templates for the TripRadar multi-application ecosystem.

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
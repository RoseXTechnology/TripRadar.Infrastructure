@description('TripRadar Server Application (Main API and Jobs API) deployed to Azure Container Apps')

targetScope = 'resourceGroup'

@description('The name prefix for the container apps')
param appNamePrefix string

@description('The location for all resources')
param location string = resourceGroup().location

@description('Environment type (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Application name for resource tagging')
param appName string

@description('Container Apps Environment ID')
param containerAppsEnvironmentId string

@description('Container Registry login server')
param containerRegistryLoginServer string

@description('Main API container image')
param mainApiImage string = '${containerRegistryLoginServer}/tripradar-main-api:latest'

@description('Jobs API container image')
param jobsApiImage string = '${containerRegistryLoginServer}/tripradar-jobs-api:latest'

@description('Database container image')
param databaseImage string = '${containerRegistryLoginServer}/tripradar-database:latest'

@description('Key Vault URI for configuration')
param keyVaultUri string

@description('Managed Identity client ID for Key Vault access')
param managedIdentityClientId string

@description('Managed Identity resource ID')
param managedIdentityId string

var commonTags = {
  Environment: environment
  Application: appName
  ManagedBy: 'Bicep'
  CostCenter: environment == 'prod' ? 'Production' : 'Development'
}

// Environment-specific resource configurations
var resourceConfig = {
  dev: {
    cpu: '0.5'
    memory: '1Gi'
    minReplicas: 1
    maxReplicas: 2
  }
  staging: {
    cpu: '1.0'
    memory: '2Gi'
    minReplicas: 1
    maxReplicas: 5
  }
  prod: {
    cpu: '2.0'
    memory: '4Gi'
    minReplicas: 2
    maxReplicas: 20
  }
}

// Main API Container App
resource mainApiContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: '${appNamePrefix}-main-api'
  location: location
  tags: commonTags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        transport: 'http'
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
        }
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
      registries: [
        {
          server: containerRegistryLoginServer
          identity: managedIdentityId
        }
      ]
      secrets: [
        {
          name: 'database-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/PostgreSQLConnectionString'
          identity: managedIdentityClientId
        }
        {
          name: 'redis-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/RedisConnectionString'
          identity: managedIdentityClientId
        }
        {
          name: 'storage-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/StorageConnectionString'
          identity: managedIdentityClientId
        }
        {
          name: 'appinsights-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/ApplicationInsights-ConnectionString'
          identity: managedIdentityClientId
        }
      ]
    }
    template: {
      containers: [
        {
          image: mainApiImage
          name: 'main-api'
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: environment == 'dev' ? 'Development' : 'Production'
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:80'
            }
            {
              name: 'ConnectionStrings__DefaultConnection'
              secretRef: 'database-connection-string'
            }
            {
              name: 'ConnectionStrings__Redis'
              secretRef: 'redis-connection-string'
            }
            {
              name: 'ConnectionStrings__Storage'
              secretRef: 'storage-connection-string'
            }
            {
              name: 'ApplicationInsights__ConnectionString'
              secretRef: 'appinsights-connection-string'
            }
            {
              name: 'OpenTelemetry__ServiceName'
              value: 'TripRadar.MainApi'
            }
            {
              name: 'OpenTelemetry__ServiceVersion'
              value: '1.0.0'
            }
            {
              name: 'Logging__LogLevel__Default'
              value: environment == 'dev' ? 'Debug' : 'Information'
            }
          ]
          resources: {
            cpu: json(resourceConfig[environment].cpu)
            memory: resourceConfig[environment].memory
          }
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 80
              }
              initialDelaySeconds: 30
              periodSeconds: 30
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/ready'
                port: 80
              }
              initialDelaySeconds: 10
              periodSeconds: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: resourceConfig[environment].minReplicas
        maxReplicas: resourceConfig[environment].maxReplicas
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
          {
            name: 'cpu-scaling'
            custom: {
              type: 'cpu'
              metadata: {
                type: 'Utilization'
                value: '70'
              }
            }
          }
        ]
      }
    }
  }
}

// Jobs API Container App
resource jobsApiContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: '${appNamePrefix}-jobs-api'
  location: location
  tags: commonTags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: false
        targetPort: 80
        transport: 'http'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
      registries: [
        {
          server: containerRegistryLoginServer
          identity: managedIdentityId
        }
      ]
      secrets: [
        {
          name: 'database-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/PostgreSQLJobsConnectionString'
          identity: managedIdentityClientId
        }
        {
          name: 'redis-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/RedisConnectionString'
          identity: managedIdentityClientId
        }
        {
          name: 'storage-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/StorageConnectionString'
          identity: managedIdentityClientId
        }
        {
          name: 'appinsights-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/ApplicationInsights-ConnectionString'
          identity: managedIdentityClientId
        }
      ]
    }
    template: {
      containers: [
        {
          image: jobsApiImage
          name: 'jobs-api'
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: environment == 'dev' ? 'Development' : 'Production'
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:80'
            }
            {
              name: 'ConnectionStrings__DefaultConnection'
              secretRef: 'database-connection-string'
            }
            {
              name: 'ConnectionStrings__Redis'
              secretRef: 'redis-connection-string'
            }
            {
              name: 'ConnectionStrings__Storage'
              secretRef: 'storage-connection-string'
            }
            {
              name: 'ApplicationInsights__ConnectionString'
              secretRef: 'appinsights-connection-string'
            }
            {
              name: 'OpenTelemetry__ServiceName'
              value: 'TripRadar.JobsApi'
            }
            {
              name: 'OpenTelemetry__ServiceVersion'
              value: '1.0.0'
            }
            {
              name: 'Logging__LogLevel__Default'
              value: environment == 'dev' ? 'Debug' : 'Information'
            }
            {
              name: 'BackgroundJobs__Enabled'
              value: 'true'
            }
            {
              name: 'BackgroundJobs__MaxConcurrency'
              value: environment == 'prod' ? '10' : '5'
            }
          ]
          resources: {
            cpu: json(resourceConfig[environment].cpu)
            memory: resourceConfig[environment].memory
          }
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 80
              }
              initialDelaySeconds: 30
              periodSeconds: 30
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/ready'
                port: 80
              }
              initialDelaySeconds: 10
              periodSeconds: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: resourceConfig[environment].minReplicas
        maxReplicas: resourceConfig[environment].maxReplicas
        rules: [
          {
            name: 'queue-length-scaling'
            custom: {
              type: 'redis'
              metadata: {
                address: '${keyVaultUri}secrets/RedisConnectionString'
                listName: 'job-queue'
                listLength: '5'
              }
              auth: [
                {
                  secretRef: 'redis-connection-string'
                  triggerParameter: 'address'
                }
              ]
            }
          }
        ]
      }
    }
  }
}

// Database Container App (if using containerized database)
resource databaseContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: '${appNamePrefix}-database'
  location: location
  tags: commonTags
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: false
        targetPort: 5432
        transport: 'tcp'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
      registries: [
        {
          server: containerRegistryLoginServer
          identity: managedIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          image: databaseImage
          name: 'database'
          env: [
            {
              name: 'POSTGRES_DB'
              value: 'tripradar'
            }
            {
              name: 'POSTGRES_USER'
              value: 'tripradar_user'
            }
            {
              name: 'POSTGRES_PASSWORD'
              value: 'secure_password_here'
            }
          ]
          resources: {
            cpu: json('1.0')
            memory: '2Gi'
          }
          volumeMounts: [
            {
              volumeName: 'database-storage'
              mountPath: '/var/lib/postgresql/data'
            }
          ]
        }
      ]
      volumes: [
        {
          name: 'database-storage'
          storageType: 'AzureFile'
          storageName: 'database-volume'
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

@description('Main API Container App resource ID')
output mainApiId string = mainApiContainerApp.id

@description('Main API Container App name')
output mainApiName string = mainApiContainerApp.name

@description('Main API FQDN')
output mainApiFqdn string = mainApiContainerApp.properties.configuration.ingress.fqdn

@description('Jobs API Container App resource ID')
output jobsApiId string = jobsApiContainerApp.id

@description('Jobs API Container App name')
output jobsApiName string = jobsApiContainerApp.name

@description('Database Container App resource ID')
output databaseId string = databaseContainerApp.id

@description('Database Container App name')
output databaseName string = databaseContainerApp.name

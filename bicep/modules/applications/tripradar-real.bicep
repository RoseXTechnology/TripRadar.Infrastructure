@description('TripRadar Real Application Deployment to Azure Container Apps')

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
param mainApiImage string = '${containerRegistryLoginServer}/tripradar-api:latest'

@description('Jobs API container image')
param jobsApiImage string = '${containerRegistryLoginServer}/tripradar-jobs-api:latest'

@description('Database container image')  
param databaseImage string = '${containerRegistryLoginServer}/tripradar-db:latest'

@description('Key Vault URI for configuration')
param keyVaultUri string

@description('Managed Identity client ID for Key Vault access')
param managedIdentityClientId string

@description('Managed Identity resource ID')
param managedIdentityId string

@description('PostgreSQL connection string (from Key Vault)')
param postgresqlConnectionString string

var commonTags = {
  Environment: environment
  Application: appName
  ManagedBy: 'Bicep'
  CostCenter: environment == 'prod' ? 'Production' : 'Development'
}

// Environment-specific resource configurations
var resourceConfig = {
  dev: {
    cpu: '1.0'
    memory: '2Gi'
    minReplicas: 1
    maxReplicas: 3
  }
  staging: {
    cpu: '1.5'
    memory: '3Gi'
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

// TripRadar Main API Container App
resource mainApiContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: '${appNamePrefix}-api'
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
        targetPort: 5330
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
          name: 'db-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/PostgreSQLConnectionString'
          identity: managedIdentityClientId
        }
        {
          name: 'redis-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/RedisConnectionString'
          identity: managedIdentityClientId
        }
        {
          name: 'appinsights-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/ApplicationInsights-ConnectionString'
          identity: managedIdentityClientId
        }
        {
          name: 'jwt-key'
          keyVaultUrl: '${keyVaultUri}secrets/JwtKey'
          identity: managedIdentityClientId
        }
        {
          name: 'app-secret'
          keyVaultUrl: '${keyVaultUri}secrets/AppSecret'
          identity: managedIdentityClientId
        }
        {
          name: 'api-key'
          keyVaultUrl: '${keyVaultUri}secrets/ApiKey'
          identity: managedIdentityClientId
        }
        {
          name: 'internal-api-key'
          keyVaultUrl: '${keyVaultUri}secrets/InternalApiKey'
          identity: managedIdentityClientId
        }
        // External API Keys
        {
          name: 'serp-api-key'
          keyVaultUrl: '${keyVaultUri}secrets/SerpApiKey'
          identity: managedIdentityClientId
        }
        {
          name: 'stripe-secret-key'
          keyVaultUrl: '${keyVaultUri}secrets/StripeSecretKey'
          identity: managedIdentityClientId
        }
        {
          name: 'stripe-publishable-key'
          keyVaultUrl: '${keyVaultUri}secrets/StripePublishableKey'
          identity: managedIdentityClientId
        }
        {
          name: 'stripe-webhook-secret'
          keyVaultUrl: '${keyVaultUri}secrets/StripeWebhookSecret'
          identity: managedIdentityClientId
        }
        {
          name: 'openweathermap-api-key'
          keyVaultUrl: '${keyVaultUri}secrets/OpenWeatherMapApiKey'
          identity: managedIdentityClientId
        }
        {
          name: 'openchargemap-api-key'
          keyVaultUrl: '${keyVaultUri}secrets/OpenChargeMapApiKey'
          identity: managedIdentityClientId
        }
        {
          name: 'unirate-api-key'
          keyVaultUrl: '${keyVaultUri}secrets/UniRateApiKey'
          identity: managedIdentityClientId
        }
        {
          name: 'calendarific-api-key'
          keyVaultUrl: '${keyVaultUri}secrets/CalendarificApiKey'
          identity: managedIdentityClientId
        }
        {
          name: 'opentripmap-api-key'
          keyVaultUrl: '${keyVaultUri}secrets/OpenTripMapApiKey'
          identity: managedIdentityClientId
        }
        {
          name: 'transitland-api-key'
          keyVaultUrl: '${keyVaultUri}secrets/TransitlandApiKey'
          identity: managedIdentityClientId
        }
        {
          name: 'google-client-id'
          keyVaultUrl: '${keyVaultUri}secrets/GoogleClientId'
          identity: managedIdentityClientId
        }
        {
          name: 'google-client-secret'
          keyVaultUrl: '${keyVaultUri}secrets/GoogleClientSecret'
          identity: managedIdentityClientId
        }
        {
          name: 'email-api-token'
          keyVaultUrl: '${keyVaultUri}secrets/EmailApiToken'
          identity: managedIdentityClientId
        }
        // Keycloak Authentication
        {
          name: 'keycloak-authority'
          keyVaultUrl: '${keyVaultUri}secrets/KeycloakAuthority'
          identity: managedIdentityClientId
        }
        {
          name: 'keycloak-audience'
          keyVaultUrl: '${keyVaultUri}secrets/KeycloakAudience'
          identity: managedIdentityClientId
        }
        {
          name: 'keycloak-client-id'
          keyVaultUrl: '${keyVaultUri}secrets/KeycloakClientId'
          identity: managedIdentityClientId
        }
        {
          name: 'keycloak-client-secret'
          keyVaultUrl: '${keyVaultUri}secrets/KeycloakClientSecret'
          identity: managedIdentityClientId
        }
        {
          name: 'keycloak-realm'
          keyVaultUrl: '${keyVaultUri}secrets/KeycloakRealm'
          identity: managedIdentityClientId
        }
        // Email Configuration
        {
          name: 'email-sender-email'
          keyVaultUrl: '${keyVaultUri}secrets/EmailSenderEmail'
          identity: managedIdentityClientId
        }
        {
          name: 'email-sender-name'
          keyVaultUrl: '${keyVaultUri}secrets/EmailSenderName'
          identity: managedIdentityClientId
        }
        {
          name: 'email-base-url'
          keyVaultUrl: '${keyVaultUri}secrets/EmailBaseUrl'
          identity: managedIdentityClientId
        }
        // Flagsmith
        {
          name: 'flagsmith-api-url'
          keyVaultUrl: '${keyVaultUri}secrets/FlagsmithApiUrl'
          identity: managedIdentityClientId
        }
        {
          name: 'flagsmith-environment-key'
          keyVaultUrl: '${keyVaultUri}secrets/FlagsmithEnvironmentKey'
          identity: managedIdentityClientId
        }
      ]
    }
    template: {
      containers: [
        {
          image: mainApiImage
          name: 'tripradar-api'
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: environment == 'dev' ? 'Development' : 'Production'
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:5330'
            }
            {
              name: 'ConnectionStrings__AppDb'
              secretRef: 'db-connection-string'
            }
            {
              name: 'ConnectionStrings__RedisConnection'
              secretRef: 'redis-connection-string'
            }
            {
              name: 'ApplicationInsights__ConnectionString'
              secretRef: 'appinsights-connection-string'
            }
            {
              name: 'JWT_KEY'
              secretRef: 'jwt-key'
            }
            {
              name: 'APP_SECRET'
              secretRef: 'app-secret'
            }
            {
              name: 'API_KEY'
              secretRef: 'api-key'
            }
            {
              name: 'INTERNAL_API_KEY'
              secretRef: 'internal-api-key'
            }
            {
              name: 'SERP_API_KEY'
              secretRef: 'serp-api-key'
            }
            {
              name: 'STRIPE_SECRET_KEY'
              secretRef: 'stripe-secret-key'
            }
            {
              name: 'STRIPE_PUBLISHABLE_KEY'
              secretRef: 'stripe-publishable-key'
            }
            {
              name: 'STRIPE_WEBHOOK_SECRET'
              secretRef: 'stripe-webhook-secret'
            }
            {
              name: 'OPENWEATHERMAP_API_KEY'
              secretRef: 'openweathermap-api-key'
            }
            {
              name: 'OPENCHARGEMAP_API_KEY'
              secretRef: 'openchargemap-api-key'
            }
            {
              name: 'UNIRATE_API_KEY'
              secretRef: 'unirate-api-key'
            }
            {
              name: 'CALENDARIFIC_API_KEY'
              secretRef: 'calendarific-api-key'
            }
            {
              name: 'OPENTRIPMAP_API_KEY'
              secretRef: 'opentripmap-api-key'
            }
            {
              name: 'TRANSITLAND_API_KEY'
              secretRef: 'transitland-api-key'
            }
            {
              name: 'GOOGLE_CLIENT_ID'
              secretRef: 'google-client-id'
            }
            {
              name: 'GOOGLE_CLIENT_SECRET'
              secretRef: 'google-client-secret'
            }
            {
              name: 'EMAIL_API_TOKEN'
              secretRef: 'email-api-token'
            }
            {
              name: 'EMAIL_SENDER_EMAIL'
              secretRef: 'email-sender-email'
            }
            {
              name: 'EMAIL_SENDER_NAME'
              secretRef: 'email-sender-name'
            }
            {
              name: 'EMAIL_BASE_URL'
              secretRef: 'email-base-url'
            }
            // Keycloak Authentication
            {
              name: 'KEYCLOAK_AUTHORITY'
              secretRef: 'keycloak-authority'
            }
            {
              name: 'KEYCLOAK_AUDIENCE'
              secretRef: 'keycloak-audience'
            }
            {
              name: 'KEYCLOAK_CLIENT_ID'
              secretRef: 'keycloak-client-id'
            }
            {
              name: 'KEYCLOAK_CLIENT_SECRET'
              secretRef: 'keycloak-client-secret'
            }
            {
              name: 'KEYCLOAK_REALM'
              secretRef: 'keycloak-realm'
            }
            // Flagsmith Feature Flags
            {
              name: 'FLAGSMITH_API_URL'
              secretRef: 'flagsmith-api-url'
            }
            {
              name: 'FLAGSMITH_ENVIRONMENT_KEY'
              secretRef: 'flagsmith-environment-key'
            }
            {
              name: 'CORS_ORIGINS'
              value: environment == 'prod' ? 'https://tripradar.io,https://www.tripradar.io' : 'http://localhost:3000,http://localhost:8888,http://localhost:1010'
            }
            // OpenTelemetry Configuration
            {
              name: 'OTEL_SERVICE_NAME'
              value: 'TripRadar.API'
            }
            {
              name: 'OTEL_SERVICE_VERSION'
              value: '1.0.0'
            }
            {
              name: 'OTEL_RESOURCE_ATTRIBUTES'
              value: 'service.name=TripRadar.API,service.version=1.0.0,deployment.environment=${environment}'
            }
            // Logging Configuration
            {
              name: 'Logging__LogLevel__Default'
              value: environment == 'dev' ? 'Debug' : 'Information'
            }
            {
              name: 'Logging__LogLevel__Microsoft__AspNetCore'
              value: 'Warning'
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
                port: 5330
              }
              initialDelaySeconds: 30
              periodSeconds: 30
              timeoutSeconds: 5
              failureThreshold: 3
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/health/ready'
                port: 5330
              }
              initialDelaySeconds: 15
              periodSeconds: 10
              timeoutSeconds: 5
              failureThreshold: 3
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
                concurrentRequests: '20'
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
          {
            name: 'memory-scaling'
            custom: {
              type: 'memory'
              metadata: {
                type: 'Utilization'
                value: '80'
              }
            }
          }
        ]
      }
    }
  }
}

// TripRadar Jobs API Container App
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
        targetPort: 5382
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
          name: 'db-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/PostgreSQLConnectionString'
          identity: managedIdentityClientId
        }
        {
          name: 'redis-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/RedisConnectionString'
          identity: managedIdentityClientId
        }
        {
          name: 'appinsights-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/ApplicationInsights-ConnectionString'
          identity: managedIdentityClientId
        }
        {
          name: 'serp-api-key'
          keyVaultUrl: '${keyVaultUri}secrets/SerpApiKey'
          identity: managedIdentityClientId
        }
        {
          name: 'openweathermap-api-key'
          keyVaultUrl: '${keyVaultUri}secrets/OpenWeatherMapApiKey'
          identity: managedIdentityClientId
        }
        {
          name: 'unirate-api-key'
          keyVaultUrl: '${keyVaultUri}secrets/UniRateApiKey'
          identity: managedIdentityClientId
        }
      ]
    }
    template: {
      containers: [
        {
          image: jobsApiImage
          name: 'tripradar-jobs-api'
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: environment == 'dev' ? 'Development' : 'Production'
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:5382'
            }
            {
              name: 'ConnectionStrings__AppDb'
              secretRef: 'db-connection-string'
            }
            {
              name: 'ConnectionStrings__RedisConnection'
              secretRef: 'redis-connection-string'
            }
            {
              name: 'ApplicationInsights__ConnectionString'
              secretRef: 'appinsights-connection-string'
            }
            {
              name: 'SERP_API_KEY'
              secretRef: 'serp-api-key'
            }
            {
              name: 'OPENWEATHERMAP_API_KEY'
              secretRef: 'openweathermap-api-key'
            }
            {
              name: 'UNIRATE_API_KEY'
              secretRef: 'unirate-api-key'
            }
            {
              name: 'Hangfire__IsFullAccessModeEnabled'
              value: environment == 'dev' ? 'true' : 'false'
            }
            {
              name: 'OTEL_SERVICE_NAME'
              value: 'TripRadar.Jobs.API'
            }
            {
              name: 'OTEL_SERVICE_VERSION'
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
                port: 5382
              }
              initialDelaySeconds: 30
              periodSeconds: 30
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/health/ready'
                port: 5382
              }
              initialDelaySeconds: 15
              periodSeconds: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: resourceConfig[environment].maxReplicas
        rules: [
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

// TripRadar Database Initialization Job
resource databaseJob 'Microsoft.App/jobs@2024-03-01' = {
  name: '${appNamePrefix}-db-init'
  location: location
  tags: commonTags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironmentId
    configuration: {
      triggerType: 'Manual'
      replicaTimeout: 1800
      replicaRetryLimit: 3
      registries: [
        {
          server: containerRegistryLoginServer
          identity: managedIdentityId
        }
      ]
      secrets: [
        {
          name: 'db-connection-string'
          keyVaultUrl: '${keyVaultUri}secrets/PostgreSQLConnectionString'
          identity: managedIdentityClientId
        }
      ]
    }
    template: {
      containers: [
        {
          image: databaseImage
          name: 'tripradar-db-init'
          env: [
            {
              name: 'DOTNET_ENVIRONMENT'
              value: environment == 'dev' ? 'Development' : 'Production'
            }
            {
              name: 'ConnectionStrings__AppDb'
              secretRef: 'db-connection-string'
            }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
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

@description('Database Job resource ID')
output databaseJobId string = databaseJob.id

@description('Database Job name')
output databaseJobName string = databaseJob.name

using '../main.bicep'

// ================================
// DEVELOPMENT ENVIRONMENT PARAMETERS
// ================================

// Basic Configuration
param environment = 'dev'
param appName = 'tripradar'

// Security Configuration
param keyVaultAdminObjectId = '00000000-0000-0000-0000-000000000000' // Replace with actual Object ID

// Database Configuration  
param postgresqlAdminUsername = 'tripradar_admin'
param postgresqlAdminPassword = 'DevPassword123!' // Should be retrieved from Key Vault in practice

// Container Images (using default images for development)
param containerImages = {
  mainApi: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
  jobsApi: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
  database: 'postgres:15-alpine'
}

// Feature Flags
param enablePrivateEndpoints = false // Disabled for cost savings in dev
param enableHighAvailability = false // Disabled for cost savings in dev

using '../main.bicep'

// ================================
// PRODUCTION ENVIRONMENT PARAMETERS
// ================================

// Basic Configuration
param environment = 'prod'
param appName = 'tripradar'

// Security Configuration
param keyVaultAdminObjectId = '00000000-0000-0000-0000-000000000000' // Replace with actual Object ID

// Database Configuration
param postgresqlAdminUsername = 'tripradar_admin'
param postgresqlAdminPassword = 'ProductionPassword123!' // Should be retrieved from Key Vault in practice

// Container Images (using production tags)
param containerImages = {
  mainApi: 'triprdaracr001.azurecr.io/tripradar-main-api:latest'
  jobsApi: 'triprdaracr001.azurecr.io/tripradar-jobs-api:latest'
  database: 'postgres:15-alpine'
}

// Feature Flags
param enablePrivateEndpoints = true // Enabled for security in production
param enableHighAvailability = true // Enabled for reliability in production

using '../main.bicep'

// ================================
// STAGING ENVIRONMENT PARAMETERS
// ================================

// Basic Configuration
param environment = 'staging'
param appName = 'tripradar'

// Security Configuration
param keyVaultAdminObjectId = '00000000-0000-0000-0000-000000000000' // Replace with actual Object ID

// Database Configuration
param postgresqlAdminUsername = 'tripradar_admin'
param postgresqlAdminPassword = 'StagingPassword123!' // Should be retrieved from Key Vault in practice

// Container Images (using staging-specific tags)
param containerImages = {
  mainApi: 'triprdaracr001.azurecr.io/tripradar-main-api:staging'
  jobsApi: 'triprdaracr001.azurecr.io/tripradar-jobs-api:staging'
  database: 'postgres:15-alpine'
}

// Feature Flags
param enablePrivateEndpoints = true // Enabled for staging to test production configuration
param enableHighAvailability = false // Disabled for cost savings in staging

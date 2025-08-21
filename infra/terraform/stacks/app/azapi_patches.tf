# AzAPI patches for Container Apps CORS and HTTP scaling rules

# CORS for API
resource "azapi_update_resource" "api_cors" {
  count       = var.enable_container_app_environment && var.enable_cors && var.api_ingress_external ? 1 : 0
  type        = "Microsoft.App/containerApps@2024-03-01"
  resource_id = module.ca_api[0].id

  body = jsonencode({
    properties = {
      configuration = {
        ingress = {
          corsPolicy = {
            allowedOrigins  = var.cors_allowed_origins
            allowedMethods  = ["GET", "POST", "OPTIONS"]
            allowedHeaders  = ["*"]
            exposeHeaders   = []
            allowCredentials = false
            # maxAge optional
          }
        }
      }
    }
  })
}

# CORS for Jobs
resource "azapi_update_resource" "jobs_cors" {
  count       = var.enable_container_app_environment && var.enable_cors && var.jobs_ingress_external ? 1 : 0
  type        = "Microsoft.App/containerApps@2024-03-01"
  resource_id = module.ca_jobs[0].id

  body = jsonencode({
    properties = {
      configuration = {
        ingress = {
          corsPolicy = {
            allowedOrigins  = var.cors_allowed_origins
            allowedMethods  = ["GET", "POST", "OPTIONS"]
            allowedHeaders  = ["*"]
            exposeHeaders   = []
            allowCredentials = false
          }
        }
      }
    }
  })
}

# CORS for Libby
resource "azapi_update_resource" "libby_cors" {
  count       = var.enable_container_app_environment && var.enable_libby && var.enable_cors && var.libby_ingress_external ? 1 : 0
  type        = "Microsoft.App/containerApps@2024-03-01"
  resource_id = module.ca_libby[0].id

  body = jsonencode({
    properties = {
      configuration = {
        ingress = {
          corsPolicy = {
            allowedOrigins  = var.cors_allowed_origins
            allowedMethods  = ["GET", "POST", "OPTIONS"]
            allowedHeaders  = ["*"]
            exposeHeaders   = []
            allowCredentials = false
          }
        }
      }
    }
  })
}

# HTTP scaling rule for API via KEDA http concurrency
resource "azapi_update_resource" "api_http_scaling" {
  count       = var.enable_container_app_environment && var.enable_http_scaling_patch ? 1 : 0
  type        = "Microsoft.App/containerApps@2024-03-01"
  resource_id = module.ca_api[0].id

  body = jsonencode({
    properties = {
      template = {
        scale = {
          rules = [
            {
              name = "http-concurrency"
              http = {
                metadata = {
                  concurrentRequests = tostring(var.api_concurrent_requests)
                }
              }
            }
          ]
        }
      }
    }
  })
}

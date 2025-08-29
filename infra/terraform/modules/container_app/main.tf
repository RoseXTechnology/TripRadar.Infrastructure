variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "environment_id" {
  type = string
}

variable "identity_id" {
  type = string
}

variable "enable_acr" {
  type = bool
}

variable "acr_server" {
  type    = string
  default = null
}

variable "acr_identity_id" {
  type    = string
  default = null
}

variable "image" {
  type = string
}

variable "port" {
  type = number
}

variable "ingress_external" {
  type = bool
}

variable "min_replicas" {
  type = number
}

variable "max_replicas" {
  type = number
}

variable "http_concurrent_requests" {
  type    = number
  default = null
}

variable "appdb_secret_id" {
  type    = string
  default = null
}

variable "appdb_conn_fallback" {
  type    = string
  default = null
}

variable "redis_secret_id" {
  type    = string
  default = null
}

variable "redis_conn_fallback" {
  type    = string
  default = null
}

variable "appi_secret_id" {
  type    = string
  default = null
}

variable "appi_conn_fallback" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "container_name" {
  type    = string
  default = "app"
}

variable "cpu" {
  type    = number
  default = 0.5
}

variable "memory" {
  type    = string
  default = "1Gi"
}

variable "create_timeout" {
  type        = string
  default     = "45m"
  description = "Timeout for creating the container app"
}

variable "update_timeout" {
  type        = string
  default     = "45m"
  description = "Timeout for updating the container app"
}

variable "delete_timeout" {
  type        = string
  default     = "15m"
  description = "Timeout for deleting the container app"
}

variable "enable_retry_on_failure" {
  type        = bool
  default     = true
  description = "Whether to enable retry logic on deployment failures"
}

variable "max_retry_attempts" {
  type        = number
  default     = 2
  description = "Maximum number of retry attempts for failed deployments"
}

variable "retry_delay_seconds" {
  type        = number
  default     = 60
  description = "Delay in seconds between retry attempts"
}

# Probe configuration variables
variable "startup_probe_initial_delay" {
  type        = number
  default     = 30
  description = "Initial delay in seconds for startup probe"
}

variable "startup_probe_period_seconds" {
  type        = number
  default     = 10
  description = "Period in seconds between startup probe checks"
}

variable "startup_probe_timeout_seconds" {
  type        = number
  default     = 5
  description = "Timeout in seconds for startup probe"
}

variable "startup_probe_failure_threshold" {
  type        = number
  default     = 12
  description = "Number of consecutive failures allowed for startup probe"
}

variable "liveness_probe_initial_delay" {
  type        = number
  default     = 60
  description = "Initial delay in seconds for liveness probe"
}

variable "liveness_probe_period_seconds" {
  type        = number
  default     = 30
  description = "Period in seconds between liveness probe checks"
}

variable "liveness_probe_timeout_seconds" {
  type        = number
  default     = 5
  description = "Timeout in seconds for liveness probe"
}

variable "liveness_probe_failure_threshold" {
  type        = number
  default     = 3
  description = "Number of consecutive failures allowed for liveness probe"
}

variable "readiness_probe_initial_delay" {
  type        = number
  default     = 30
  description = "Initial delay in seconds for readiness probe"
}

variable "readiness_probe_period_seconds" {
  type        = number
  default     = 10
  description = "Period in seconds between readiness probe checks"
}

variable "readiness_probe_timeout_seconds" {
  type        = number
  default     = 5
  description = "Timeout in seconds for readiness probe"
}

variable "readiness_probe_failure_threshold" {
  type        = number
  default     = 3
  description = "Number of consecutive failures allowed for readiness probe"
}

resource "azurerm_container_app" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.environment_id
  revision_mode                = "Multiple"

  timeouts {
    create = var.create_timeout
    update = var.update_timeout
    delete = var.delete_timeout
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  dynamic "registry" {
    for_each = var.enable_acr ? [1] : []
    content {
      server   = var.acr_server
      identity = coalesce(var.acr_identity_id, var.identity_id)
    }
  }

  dynamic "ingress" {
    for_each = var.ingress_external ? [1] : []
    content {
      external_enabled           = var.ingress_external
      target_port                = var.port
      transport                  = "auto"
      allow_insecure_connections = false

      traffic_weight {
        latest_revision = true
        percentage      = 100
      }
    }
  }

  dynamic "secret" {
    for_each = var.appdb_secret_id != null || var.appdb_conn_fallback != null ? [1] : []
    content {
      name                = "appdb-conn"
      key_vault_secret_id = var.appdb_secret_id
      identity            = var.appdb_secret_id != null ? var.identity_id : null
      value               = var.appdb_secret_id == null ? var.appdb_conn_fallback : null
    }
  }

  dynamic "secret" {
    for_each = var.redis_secret_id != null || var.redis_conn_fallback != null ? [1] : []
    content {
      name                = "redis-conn"
      key_vault_secret_id = var.redis_secret_id
      identity            = var.redis_secret_id != null ? var.identity_id : null
      value               = var.redis_secret_id == null ? var.redis_conn_fallback : null
    }
  }

  dynamic "secret" {
    for_each = (var.appi_secret_id != null && var.appi_secret_id != "") || (var.appi_conn_fallback != null && var.appi_conn_fallback != "") ? [1] : []
    content {
      name                = "appi-conn"
      key_vault_secret_id = var.appi_secret_id != null && var.appi_secret_id != "" ? var.appi_secret_id : null
      identity            = var.appi_secret_id != null && var.appi_secret_id != "" ? var.identity_id : null
      value               = (var.appi_secret_id == null || var.appi_secret_id == "") && var.appi_conn_fallback != null && var.appi_conn_fallback != "" ? var.appi_conn_fallback : null
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.container_name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      env {
        name  = "ASPNETCORE_URLS"
        value = "http://0.0.0.0:${var.port}"
      }

      # AppDb connection string via KV secret or fallback value (only if provided)
      dynamic "env" {
        for_each = (var.appdb_secret_id != null || var.appdb_conn_fallback != null) ? [1] : []
        content {
          name        = "ConnectionStrings__AppDb"
          secret_name = var.appdb_secret_id != null ? "appdb-conn" : null
          value       = var.appdb_secret_id == null ? var.appdb_conn_fallback : null
        }
      }

      # Redis connection string via KV secret or fallback value (only if provided)
      dynamic "env" {
        for_each = (var.redis_secret_id != null || var.redis_conn_fallback != null) ? [1] : []
        content {
          name        = "ConnectionStrings__RedisConnection"
          secret_name = var.redis_secret_id != null ? "redis-conn" : null
          value       = var.redis_secret_id == null ? var.redis_conn_fallback : null
        }
      }

      # Application Insights connection string via KV secret or fallback value (only if provided)
      dynamic "env" {
        for_each = (var.appi_secret_id != null && var.appi_secret_id != "") || (var.appi_conn_fallback != null && var.appi_conn_fallback != "") ? [1] : []
        content {
          name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
          secret_name = var.appi_secret_id != null && var.appi_secret_id != "" ? "appi-conn" : null
          value       = (var.appi_secret_id == null || var.appi_secret_id == "") && var.appi_conn_fallback != null && var.appi_conn_fallback != "" ? var.appi_conn_fallback : null
        }
      }

      startup_probe {
        transport = "TCP"
        port      = var.port
      }

      liveness_probe {
        transport = "TCP"
        port      = var.port
      }

      readiness_probe {
        transport = "TCP"
        port      = var.port
      }
    }
  }

  tags = var.tags
}

# Retry logic for handling transient deployment failures
resource "null_resource" "retry_deployment" {
  count = var.enable_retry_on_failure ? 1 : 0

  triggers = {
    container_app_id = azurerm_container_app.this.id
    image           = var.image
    timestamp       = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -e

      MAX_ATTEMPTS=${var.max_retry_attempts}
      RETRY_DELAY=${var.retry_delay_seconds}
      CONTAINER_NAME="${var.name}"
      RESOURCE_GROUP="${var.resource_group_name}"
      ATTEMPT=1

      echo "Starting deployment retry logic for $CONTAINER_NAME..."

      while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS for container app $CONTAINER_NAME"

        # Check if container app is in a healthy state
        STATUS=$(az containerapp show --name "$CONTAINER_NAME" --resource-group "$RESOURCE_GROUP" --query "properties.provisioningState" -o tsv 2>/dev/null || echo "Failed")

        if [ "$STATUS" = "Succeeded" ]; then
          echo "Container app $CONTAINER_NAME is successfully provisioned"
          exit 0
        elif [ "$STATUS" = "Failed" ]; then
          echo "Container app $CONTAINER_NAME provisioning failed on attempt $ATTEMPT"

          if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
            echo "Max retry attempts reached. Manual intervention may be required."
            exit 1
          fi

          echo "Waiting $RETRY_DELAY seconds before retry..."
          sleep $RETRY_DELAY
          ATTEMPT=$((ATTEMPT + 1))

          # Trigger a revision update to retry deployment
          echo "Triggering revision update for $CONTAINER_NAME..."
          az containerapp revision set-mode --name "$CONTAINER_NAME" --resource-group "$RESOURCE_GROUP" --mode Multiple --yes 2>/dev/null || true
        else
          echo "Container app $CONTAINER_NAME is still provisioning (status: $STATUS)"
          sleep 30
        fi
      done
    EOT

    interpreter = ["bash", "-c"]
  }

  depends_on = [azurerm_container_app.this]
}

output "id" {
  value = azurerm_container_app.this.id
}

output "name" {
  value = azurerm_container_app.this.name
}

output "fqdn" {
  value = try(azurerm_container_app.this.ingress[0].fqdn, null)
}

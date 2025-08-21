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

resource "azurerm_container_app" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.environment_id
  revision_mode                = "Single"

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
    for_each = var.appi_secret_id != null || var.appi_conn_fallback != null ? [1] : []
    content {
      name                = "appi-conn"
      key_vault_secret_id = var.appi_secret_id
      identity            = var.appi_secret_id != null ? var.identity_id : null
      value               = var.appi_secret_id == null ? var.appi_conn_fallback : null
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

      # AppDb connection string via KV secret or fallback value
      env {
        name        = "ConnectionStrings__AppDb"
        secret_name = var.appdb_secret_id != null ? "appdb-conn" : null
        value       = var.appdb_secret_id == null ? var.appdb_conn_fallback : null
      }

      # Redis connection string via KV secret or fallback value
      env {
        name        = "ConnectionStrings__RedisConnection"
        secret_name = var.redis_secret_id != null ? "redis-conn" : null
        value       = var.redis_secret_id == null ? var.redis_conn_fallback : null
      }

      # Application Insights connection string via KV secret or fallback value
      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = var.appi_secret_id != null ? "appi-conn" : null
        value       = var.appi_secret_id == null ? var.appi_conn_fallback : null
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

output "id" {
  value = azurerm_container_app.this.id
}

output "fqdn" {
  value = try(azurerm_container_app.this.ingress[0].fqdn, null)
}

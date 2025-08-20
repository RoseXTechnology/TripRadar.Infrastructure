# Container Apps for API and Jobs

locals {
  kv_postgres_secret_id = var.enable_key_vault && var.write_secrets_to_key_vault && var.enable_postgres && length(azurerm_key_vault_secret.postgres_connection_string) > 0 ? azurerm_key_vault_secret.postgres_connection_string[0].id : null
  kv_redis_secret_id    = var.enable_key_vault && var.write_secrets_to_key_vault && var.enable_redis    && length(azurerm_key_vault_secret.redis_connection_string) > 0    ? azurerm_key_vault_secret.redis_connection_string[0].id    : null
  kv_appi_secret_id     = var.enable_key_vault && var.write_secrets_to_key_vault && var.enable_app_insights && length(azurerm_key_vault_secret.app_insights_connection_string) > 0 ? azurerm_key_vault_secret.app_insights_connection_string[0].id : null
  appi_conn_string      = try(azurerm_application_insights.appi[0].connection_string, null)
}

resource "azurerm_container_app" "api" {
  count               = var.enable_container_app_environment ? 1 : 0
  name                = "${var.project}-${var.environment}-api"
  resource_group_name = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.cae[0].id
  revision_mode       = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.api.id]
  }

  dynamic "registry" {
    for_each = var.enable_acr ? [1] : []
    content {
      server   = azurerm_container_registry.acr[0].login_server
      identity = azurerm_user_assigned_identity.api.id
    }
  }

  ingress {
    external_enabled           = var.api_ingress_external
    target_port                = var.api_port
    transport                  = "auto"
    allow_insecure_connections = false
  }

  secret {
    name                  = "appdb-conn"
    key_vault_secret_id   = local.kv_postgres_secret_id
    identity              = local.kv_postgres_secret_id != null ? azurerm_user_assigned_identity.api.id : null
  }

  secret {
    name                  = "redis-conn"
    key_vault_secret_id   = local.kv_redis_secret_id
    identity              = local.kv_redis_secret_id != null ? azurerm_user_assigned_identity.api.id : null
  }

  secret {
    name                = "appi-conn"
    key_vault_secret_id = local.kv_appi_secret_id
    identity            = local.kv_appi_secret_id != null ? azurerm_user_assigned_identity.api.id : null
    value               = local.kv_appi_secret_id == null && local.appi_conn_string != null ? local.appi_conn_string : null
  }

  template {
    min_replicas = var.api_min_replicas
    max_replicas = var.api_max_replicas

    container {
      name   = "api"
      image  = coalesce(var.api_image, "mcr.microsoft.com/dotnet/samples:aspnetapp")
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "ASPNETCORE_URLS"
        value = "http://0.0.0.0:${var.api_port}"
      }

      env {
        name        = "ConnectionStrings__AppDb"
        secret_name = local.kv_postgres_secret_id != null ? "appdb-conn" : null
        value       = local.kv_postgres_secret_id == null && var.enable_postgres ? local.postgres_connection_string : null
      }

      env {
        name        = "ConnectionStrings__RedisConnection"
        secret_name = local.kv_redis_secret_id != null ? "redis-conn" : null
        value       = local.kv_redis_secret_id == null && var.enable_redis ? local.redis_connection_string : null
      }

      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = local.kv_appi_secret_id != null ? "appi-conn" : null
        value       = local.kv_appi_secret_id == null && local.appi_conn_string != null ? local.appi_conn_string : null
      }

      liveness_probe {
        transport = "HTTP"
        port      = var.api_port
        path      = "/health"
        interval  = 10
        timeout   = 3
        initial_delay = 10
      }

      readiness_probe {
        transport = "HTTP"
        port      = var.api_port
        path      = "/health"
        interval  = 10
        timeout   = 3
        initial_delay = 10
      }
    }

    scale {
      min_replicas = var.api_min_replicas
      max_replicas = var.api_max_replicas

      rule {
        name = "http-traffic"
        http {
          concurrent_requests = var.api_concurrent_requests
        }
      }
    }
  }

  tags = merge(var.tags, { Environment = var.environment, Project = var.project })
}

# Jobs Container App (no public ingress by default)
resource "azurerm_container_app" "jobs" {
  count               = var.enable_container_app_environment ? 1 : 0
  name                = "${var.project}-${var.environment}-jobs"
  resource_group_name = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.cae[0].id
  revision_mode       = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.jobs.id]
  }

  dynamic "registry" {
    for_each = var.enable_acr ? [1] : []
    content {
      server   = azurerm_container_registry.acr[0].login_server
      identity = azurerm_user_assigned_identity.jobs.id
    }
  }

  dynamic "ingress" {
    for_each = var.jobs_ingress_external ? [1] : []
    content {
      external_enabled           = var.jobs_ingress_external
      target_port                = var.jobs_port
      transport                  = "auto"
      allow_insecure_connections = false
    }
  }

  secret {
    name                  = "appdb-conn"
    key_vault_secret_id   = local.kv_postgres_secret_id
    identity              = local.kv_postgres_secret_id != null ? azurerm_user_assigned_identity.jobs.id : null
  }

  secret {
    name                  = "redis-conn"
    key_vault_secret_id   = local.kv_redis_secret_id
    identity              = local.kv_redis_secret_id != null ? azurerm_user_assigned_identity.jobs.id : null
  }

  secret {
    name                = "appi-conn"
    key_vault_secret_id = local.kv_appi_secret_id
    identity            = local.kv_appi_secret_id != null ? azurerm_user_assigned_identity.jobs.id : null
    value               = local.kv_appi_secret_id == null && local.appi_conn_string != null ? local.appi_conn_string : null
  }

  template {
    min_replicas = var.jobs_min_replicas
    max_replicas = var.jobs_max_replicas

    container {
      name   = "jobs"
      image  = coalesce(var.jobs_image, "mcr.microsoft.com/dotnet/samples:aspnetapp")
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "ASPNETCORE_URLS"
        value = "http://0.0.0.0:${var.jobs_port}"
      }

      env {
        name        = "ConnectionStrings__AppDb"
        secret_name = local.kv_postgres_secret_id != null ? "appdb-conn" : null
        value       = local.kv_postgres_secret_id == null && var.enable_postgres ? local.postgres_connection_string : null
      }

      env {
        name        = "ConnectionStrings__RedisConnection"
        secret_name = local.kv_redis_secret_id != null ? "redis-conn" : null
        value       = local.kv_redis_secret_id == null && var.enable_redis ? local.redis_connection_string : null
      }

      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = local.kv_appi_secret_id != null ? "appi-conn" : null
        value       = local.kv_appi_secret_id == null && local.appi_conn_string != null ? local.appi_conn_string : null
      }

      liveness_probe {
        transport = "TCP"
        port      = var.jobs_port
        interval  = 10
        timeout   = 3
        initial_delay = 10
      }

      readiness_probe {
        transport = "TCP"
        port      = var.jobs_port
        interval  = 10
        timeout   = 3
        initial_delay = 10
      }
    }

    scale {
      min_replicas = var.jobs_min_replicas
      max_replicas = var.jobs_max_replicas
    }
  }

  tags = merge(var.tags, { Environment = var.environment, Project = var.project })
}

# Azure Cache for Redis (optional)
resource "azurerm_redis_cache" "redis" {
  count               = var.enable_redis ? 1 : 0
  name                = coalesce(var.redis_name, lower(replace("${var.project}-${var.environment}-redis", "_", "-")))
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  capacity = var.redis_capacity
  family   = var.redis_family
  sku_name = var.redis_sku_name

  minimum_tls_version = "1.2"
  non_ssl_port_enabled = false

  redis_configuration {}

  tags = merge(var.tags, { Environment = var.environment, Project = var.project })
  lifecycle {
    prevent_destroy = true
  }
}

# Azure Front Door (Standard/Premium) for API ingress

locals {
  fd_enabled               = var.fd_enable && var.enable_container_app_environment
  fd_custom_domain_enabled = var.fd_enable && var.enable_container_app_environment && try(length(var.fd_custom_domain) > 0, false)
  fd_waf_enabled           = var.fd_enable && var.enable_container_app_environment && var.fd_waf_enable
}

resource "azurerm_cdn_frontdoor_profile" "fd" {
  count               = local.fd_enabled ? 1 : 0
  name                = "${var.project}-${var.environment}-afd"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = var.fd_profile_sku
  tags                = merge(var.tags, { Environment = var.environment, Project = var.project })
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "fd" {
  count                    = local.fd_enabled ? 1 : 0
  name                     = "${var.project}-${var.environment}-fd-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd[0].id
  lifecycle {
    prevent_destroy = true
  }
}

# Optional custom domain for Front Door
resource "azurerm_cdn_frontdoor_custom_domain" "api" {
  count                    = local.fd_custom_domain_enabled ? 1 : 0
  name                     = "api-domain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd[0].id
  host_name                = var.fd_custom_domain

  tls {
    certificate_type = "ManagedCertificate"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "api_blue" {
  count                    = local.fd_enabled ? 1 : 0
  name                     = "api-blue"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd[0].id

  health_probe {
    interval_in_seconds = 60
    path                = "/"
    protocol            = "Https"
    request_type        = "GET"
  }

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 4
    successful_samples_required        = 3
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_origin" "api_blue" {
  count                         = local.fd_enabled ? 1 : 0
  name                          = "api-origin-blue"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.api_blue[0].id

  enabled                        = true
  host_name                      = module.ca_api[0].fqdn
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = module.ca_api[0].fqdn
  certificate_name_check_enabled = true
  priority                       = 1
  weight                         = 1000
  lifecycle {
    prevent_destroy = true
  }
}

# Green slot origin group and origin
resource "azurerm_cdn_frontdoor_origin_group" "api_green" {
  count                    = local.fd_enabled ? 1 : 0
  name                     = "api-green"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd[0].id

  health_probe {
    interval_in_seconds = 60
    path                = "/"
    protocol            = "Https"
    request_type        = "GET"
  }

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 4
    successful_samples_required        = 3
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_origin" "api_green" {
  count                         = local.fd_enabled ? 1 : 0
  name                          = "api-origin-green"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.api_green[0].id

  enabled                        = true
  host_name                      = module.ca_api[0].fqdn
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = module.ca_api[0].fqdn
  certificate_name_check_enabled = true
  priority                       = 1
  weight                         = 1000
  lifecycle {
    prevent_destroy = true
  }
}

locals {
  fd_active_group_id   = local.fd_enabled ? (var.fd_active_slot == "blue" ? azurerm_cdn_frontdoor_origin_group.api_blue[0].id : azurerm_cdn_frontdoor_origin_group.api_green[0].id) : null
  fd_active_origin_ids = local.fd_enabled ? (var.fd_active_slot == "blue" ? [azurerm_cdn_frontdoor_origin.api_blue[0].id] : [azurerm_cdn_frontdoor_origin.api_green[0].id]) : []
}

resource "azurerm_cdn_frontdoor_route" "api" {
  count                           = local.fd_enabled ? 1 : 0
  name                            = "api-route"
  cdn_frontdoor_endpoint_id       = azurerm_cdn_frontdoor_endpoint.fd[0].id
  cdn_frontdoor_origin_group_id   = local.fd_active_group_id
  cdn_frontdoor_origin_ids        = local.fd_active_origin_ids
  cdn_frontdoor_custom_domain_ids = local.fd_custom_domain_enabled ? [azurerm_cdn_frontdoor_custom_domain.api[0].id] : []

  https_redirect_enabled = true
  forwarding_protocol    = var.fd_forwarding_protocol
  patterns_to_match      = var.fd_route_patterns
  link_to_default_domain = true

  supported_protocols = ["Https"]

  depends_on = [
    module.ca_api
  ]
  lifecycle {
    prevent_destroy = true
  }
}

# Front Door WAF policy (optional)
resource "azurerm_cdn_frontdoor_firewall_policy" "fd" {
  count               = local.fd_waf_enabled ? 1 : 0
  name                = replace("${var.project}${var.environment}AfdWaf", "[^A-Za-z0-9]", "")
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = var.fd_profile_sku
  mode                = "Prevention"
  enabled             = true

  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
    action  = "Block"
  }

  # Note: prevent_destroy removed to allow proper count-based lifecycle management
  # If you need to protect this resource, consider using -target flags during apply
}

# Associate WAF policy to endpoint (and custom domain if present)
resource "azurerm_cdn_frontdoor_security_policy" "fd" {
  count                    = local.fd_waf_enabled ? 1 : 0
  name                     = replace("${var.project}${var.environment}AfdSp", "[^A-Za-z0-9]", "")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd[0].id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.fd[0].id

      association {
        patterns_to_match = ["/*"]

        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.fd[0].id
        }

        dynamic "domain" {
          for_each = local.fd_custom_domain_enabled ? [1] : []
          content {
            cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.api[0].id
          }
        }
      }
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}

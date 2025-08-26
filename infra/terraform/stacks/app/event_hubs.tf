# Azure Event Hubs (Kafka-compatible) – optional

resource "azurerm_eventhub_namespace" "eh" {
  count               = var.enable_event_hubs ? 1 : 0
  name                = coalesce(var.event_hubs_namespace_name, lower(replace("${var.project}-${var.environment}-ehns", "_", "-")))
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  sku  = "Standard"
  capacity = 1

  public_network_access_enabled = var.event_hubs_public_network_access_enabled

  tags = merge(var.tags, { Environment = var.environment, Project = var.project })
  lifecycle {
    prevent_destroy = true
  }
}

# Blue/Green Event Hubs within a single namespace
resource "azurerm_eventhub" "hub_blue" {
  count         = var.enable_event_hubs ? 1 : 0
  name          = var.event_hub_name
  namespace_id  = azurerm_eventhub_namespace.eh[0].id

  partition_count   = var.event_hub_partitions
  message_retention = var.event_hub_message_retention
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_eventhub" "hub_green" {
  count         = var.enable_event_hubs ? 1 : 0
  name          = "${var.event_hub_name}-green"
  namespace_id  = azurerm_eventhub_namespace.eh[0].id

  partition_count   = var.event_hub_partitions
  message_retention = var.event_hub_message_retention
  lifecycle {
    prevent_destroy = true
  }
}

# Namespace-scoped rule for producers (send)
resource "azurerm_eventhub_namespace_authorization_rule" "send" {
  count               = var.enable_event_hubs ? 1 : 0
  name                = "send"
  namespace_name      = azurerm_eventhub_namespace.eh[0].name
  resource_group_name = azurerm_resource_group.rg.name

  listen = false
  send   = true
  manage = false
  lifecycle {
    prevent_destroy = true
  }
}

// Event Hub-scoped rule for consumers (listen) - blue
resource "azurerm_eventhub_authorization_rule" "hub_listen_blue" {
  count               = var.enable_event_hubs ? 1 : 0
  name                = "listen"
  namespace_name      = azurerm_eventhub_namespace.eh[0].name
  eventhub_name       = azurerm_eventhub.hub_blue[0].name
  resource_group_name = azurerm_resource_group.rg.name

  listen = true
  send   = false
  manage = false
  lifecycle {
    prevent_destroy = true
  }
}

// Event Hub-scoped rule for consumers (listen) - green
resource "azurerm_eventhub_authorization_rule" "hub_listen_green" {
  count               = var.enable_event_hubs ? 1 : 0
  name                = "listen"
  namespace_name      = azurerm_eventhub_namespace.eh[0].name
  eventhub_name       = azurerm_eventhub.hub_green[0].name
  resource_group_name = azurerm_resource_group.rg.name

  listen = true
  send   = false
  manage = false
  lifecycle {
    prevent_destroy = true
  }
}

locals {
  event_hubs_kafka_bootstrap = var.enable_event_hubs ? format("%s.servicebus.windows.net:9093", azurerm_eventhub_namespace.eh[0].name) : null
  active_event_hub_name = var.enable_event_hubs ? (var.eh_active_slot == "blue" ? azurerm_eventhub.hub_blue[0].name : azurerm_eventhub.hub_green[0].name) : null
  active_event_hub_listen_connection_string = var.enable_event_hubs ? (
    var.eh_active_slot == "blue" ? azurerm_eventhub_authorization_rule.hub_listen_blue[0].primary_connection_string : azurerm_eventhub_authorization_rule.hub_listen_green[0].primary_connection_string
  ) : null
  event_hubs_send_ns_connection_string = var.enable_event_hubs ? azurerm_eventhub_namespace_authorization_rule.send[0].primary_connection_string : null
}

# State migration for blue/green rename
moved {
  from = azurerm_eventhub.hub
  to   = azurerm_eventhub.hub_blue
}

moved {
  from = azurerm_eventhub_authorization_rule.hub_listen
  to   = azurerm_eventhub_authorization_rule.hub_listen_blue
}

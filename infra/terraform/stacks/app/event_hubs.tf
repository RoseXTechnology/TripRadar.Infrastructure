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
}

resource "azurerm_eventhub" "hub" {
  count         = var.enable_event_hubs ? 1 : 0
  name          = var.event_hub_name
  namespace_id  = azurerm_eventhub_namespace.eh[0].id

  partition_count   = var.event_hub_partitions
  message_retention = var.event_hub_message_retention
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
}

# Event Hub-scoped rule for consumers (listen)
resource "azurerm_eventhub_authorization_rule" "hub_listen" {
  count               = var.enable_event_hubs ? 1 : 0
  name                = "listen"
  namespace_name      = azurerm_eventhub_namespace.eh[0].name
  eventhub_name       = azurerm_eventhub.hub[0].name
  resource_group_name = azurerm_resource_group.rg.name

  listen = true
  send   = false
  manage = false
}

locals {
  event_hubs_kafka_bootstrap = var.enable_event_hubs ? format("%s.servicebus.windows.net:9093", azurerm_eventhub_namespace.eh[0].name) : null
}

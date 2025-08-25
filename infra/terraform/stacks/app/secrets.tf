# Optionally publish secrets to Key Vault
# Requires the deploying identity to have Key Vault Secrets Officer on the vault

resource "azurerm_key_vault_secret" "postgres_connection_string" {
  count        = var.enable_key_vault && var.write_secrets_to_key_vault && var.enable_postgres && local.postgres_connection_string != null ? 1 : 0
  name         = "app-database-connection-string"
  value        = local.postgres_connection_string
  key_vault_id = azurerm_key_vault.kv[0].id
  content_type = "connection-string"
}

resource "azurerm_key_vault_secret" "redis_connection_string" {
  count        = var.enable_key_vault && var.write_secrets_to_key_vault && var.enable_redis && local.redis_connection_string != null ? 1 : 0
  name         = "app-redis-connection-string"
  value        = local.redis_connection_string
  key_vault_id = azurerm_key_vault.kv[0].id
  content_type = "connection-string"
}

resource "azurerm_key_vault_secret" "app_insights_connection_string" {
  count        = var.enable_key_vault && var.write_secrets_to_key_vault && var.enable_app_insights ? 1 : 0
  name         = "app-insights-connection-string"
  value        = azurerm_application_insights.appi[0].connection_string
  key_vault_id = azurerm_key_vault.kv[0].id
  content_type = "connection-string"
}

# Event Hubs secrets (optional)
resource "azurerm_key_vault_secret" "eventhubs_send_connection_string" {
  count        = var.enable_key_vault && var.write_secrets_to_key_vault && var.enable_event_hubs ? 1 : 0
  name         = "eventhubs-send-connection-string"
  value        = azurerm_eventhub_namespace_authorization_rule.send[0].primary_connection_string
  key_vault_id = azurerm_key_vault.kv[0].id
  content_type = "connection-string"
}

resource "azurerm_key_vault_secret" "eventhubs_listen_connection_string" {
  count        = var.enable_key_vault && var.write_secrets_to_key_vault && var.enable_event_hubs ? 1 : 0
  name         = "eventhubs-listen-connection-string"
  value        = azurerm_eventhub_authorization_rule.hub_listen[0].primary_connection_string
  key_vault_id = azurerm_key_vault.kv[0].id
  content_type = "connection-string"
}

resource "azurerm_key_vault_secret" "eventhubs_kafka_bootstrap" {
  count        = var.enable_key_vault && var.write_secrets_to_key_vault && var.enable_event_hubs ? 1 : 0
  name         = "eventhubs-kafka-bootstrap"
  value        = local.event_hubs_kafka_bootstrap
  key_vault_id = azurerm_key_vault.kv[0].id
  content_type = "hostname:port"
}

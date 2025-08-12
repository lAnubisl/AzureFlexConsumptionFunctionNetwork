resource "azurerm_log_analytics_workspace" "log" {
  name                = "log-${random_string.random.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = module.naming.tags
}

resource "azurerm_application_insights" "appi" {
  name                = "appi-${random_string.random.result}"
  location            = aazurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.logs.id
  application_type    = "other"
  retention_in_days   = 30
}
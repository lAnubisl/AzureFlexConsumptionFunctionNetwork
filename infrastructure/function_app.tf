resource "azurerm_storage_account" "st_function_app" {
  name                     = "stfunc${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  shared_access_key_enabled = false
}

resource "azurerm_storage_container" "sc_funtion_app" {
  name                  = "example-flexcontainer"
  storage_account_id    = azurerm_storage_account.st_function_app.id
  container_access_type = "private"
}

resource "azurerm_service_plan" "asp" {
  name                = "app-service-plan-${random_string.random.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = "FC1"
  os_type             = "Linux"
}

resource "azurerm_function_app_flex_consumption" "func" {
  name                = "func-${random_string.random.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp.id

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.st_function_app.primary_blob_endpoint}${azurerm_storage_container.st_function_app.name}"
  storage_authentication_type = "SystemAssignedIdentity"
  runtime_name                = "python"
  runtime_version             = "3.11"
  maximum_instance_count      = 1
  instance_memory_in_mb       = 512
  site_config {
    minimum_tls_version = "1.3"
  }
  identity {
    type = "SystemAssigned"
  }
  lifecycle {
    ignore_changes = [
      virtual_network_subnet_id
    ]
  }
}

resource "azurerm_role_assignment" "function_app_storage_container_role_assignment" {
  scope                = azurerm_storage_container.sc_funtion_app.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.func.identity[0].principal_id
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_webapp" {
  app_service_id = azurerm_function_app_flex_consumption.func.id
  subnet_id      = azurerm_subnet.func_subnet.id
}

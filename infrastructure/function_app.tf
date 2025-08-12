resource "azurerm_storage_account" "st_function_app" {
  name                            = "stfunc${random_string.random.result}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  shared_access_key_enabled       = true
  default_to_oauth_authentication = false
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
  storage_container_endpoint  = "${azurerm_storage_account.st_function_app.primary_blob_endpoint}${azurerm_storage_container.sc_funtion_app.name}"
  storage_authentication_type = "SystemAssignedIdentity"
  runtime_name                = "python"
  runtime_version             = "3.11"
  maximum_instance_count      = 40
  instance_memory_in_mb       = 512
  site_config {
    minimum_tls_version                    = "1.3"
    application_insights_connection_string = azurerm_application_insights.appi.connection_string
  }
  identity {
    type = "SystemAssigned"
  }
  app_settings = {
    # https://learn.microsoft.com/en-us/troubleshoot/azure/azure-monitor/app-insights/telemetry/opentelemetry-troubleshooting-python#duplicate-trace-logs-in-azure-functions
    # ### Duplicate trace logs in Azure Functions ###
    # If you see a pair of entries for each trace log within Application Insights, you probably enabled the following types of logging instrumentation:
    # The native logging instrumentation in Azure Functions
    # The azure-monitor-opentelemetry logging instrumentation within the distribution
    # To prevent duplication, you can disable the distribution's logging, but leave the native logging instrumentation in Azure Functions enabled. To do this, set the OTEL_LOGS_EXPORTER environment variable to None.
    OTEL_LOGS_EXPORTER = "None"
    # https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-configuration?tabs=python#set-the-cloud-role-name-and-the-cloud-role-instance
    OTEL_SERVICE_NAME        = "MyFunctionApp"
    OTEL_RESOURCE_ATTRIBUTES = "service.instance.id=MyFunctionApp"

    STORAGE_ACCOUNT_NAME   = azurerm_storage_account.st_metadata.name
    STORAGE_CONTAINER_NAME = azurerm_storage_container.sc_metadata.name

    # https://github.com/hashicorp/terraform-provider-azurerm/issues/29993
    AzureWebJobsStorage__blobServiceUri  = azurerm_storage_account.st_function_app.primary_blob_endpoint
    AzureWebJobsStorage__queueServiceUri = azurerm_storage_account.st_function_app.primary_queue_endpoint
    AzureWebJobsStorage__tableServiceUri = azurerm_storage_account.st_function_app.primary_table_endpoint
    AzureWebJobsStorage__fileServiceUri  = azurerm_storage_account.st_function_app.primary_file_endpoint
  }
  lifecycle {
    ignore_changes = [
      virtual_network_subnet_id
    ]
  }
}

resource "azurerm_role_assignment" "ra_func_st" {
  scope                = azurerm_storage_account.st_function_app.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.func.identity[0].principal_id
}

resource "azurerm_role_assignment" "ra_func_sc_metadata" {
  scope                = azurerm_storage_container.sc_metadata.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.func.identity[0].principal_id
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_webapp" {
  app_service_id = azurerm_function_app_flex_consumption.func.id
  subnet_id      = azurerm_subnet.func_subnet.id
}

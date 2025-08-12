resource "azurerm_storage_account" "st_metadata" {
  name                            = "stmetadata${random_string.random.result}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  default_to_oauth_authentication = true
  shared_access_key_enabled       = false
  public_network_access_enabled   = true
  is_hns_enabled                  = false
  access_tier                     = "Hot"
  min_tls_version                 = "TLS1_2"
}

resource "azurerm_storage_container" "sc_metadata" {
  name                  = "metadata"
  storage_account_id    = azurerm_storage_account.st_metadata.id
  container_access_type = "private"
}

resource "azurerm_private_dns_zone" "privatelink_dfs_core_windows_net" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_privatelink_dfs_azure_com" {
  name                  = azurerm_virtual_network.vnet.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_dfs_core_windows_net.name
}

resource "azurerm_private_endpoint" "private_endpoint_st_metadata" {
  name                = "pe-${azurerm_storage_account.st_metadata.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.network_services_subnet.id

  private_service_connection {
    name                           = "pe-conn-${azurerm_storage_account.st_metadata.name}"
    private_connection_resource_id = azurerm_storage_account.st_metadata.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_dfs_core_windows_net.id]
  }
}

resource "azurerm_storage_blob" "test_blob" {
  name                   = "test.txt"
  storage_account_name   = azurerm_storage_account.st_metadata.name
  storage_container_name = azurerm_storage_container.sc_metadata.name
  type                   = "Block"
  source                 = "test.txt"
}
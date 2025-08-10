resource "random_string" "random" {
  length   = 8
  special = false
  upper   = false
  lower   = true
  numeric = false
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${random_string.random.result}"
  location = var.resource_group_location
}
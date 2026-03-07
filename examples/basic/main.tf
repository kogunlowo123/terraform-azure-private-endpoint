provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-pe-basic"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-pe-basic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "endpoints" {
  name                 = "snet-endpoints"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_storage_account" "example" {
  name                     = "stpebasicexample01"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

module "private_endpoint" {
  source = "../../"

  private_endpoints = {
    "storage-blob" = {
      name                = "pe-storage-blob"
      resource_group_name = azurerm_resource_group.example.name
      location            = azurerm_resource_group.example.location
      subnet_id           = azurerm_subnet.endpoints.id

      private_service_connection = {
        name                           = "psc-storage-blob"
        private_connection_resource_id = azurerm_storage_account.example.id
        subresource_names              = ["blob"]
      }
    }
  }

  default_tags = {
    Environment = "dev"
  }
}

output "private_endpoint_ids" {
  value = module.private_endpoint.private_endpoint_ids
}

output "private_endpoint_ips" {
  value = module.private_endpoint.private_endpoint_ip_addresses
}

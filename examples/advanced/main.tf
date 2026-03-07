provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-pe-advanced"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-pe-advanced"
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
  name                     = "stpeadvexample01"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_key_vault" "example" {
  name                = "kv-pe-advanced-01"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

data "azurerm_client_config" "current" {}

module "private_endpoint" {
  source = "../../"

  private_dns_zones = {
    "blob" = {
      name                = "privatelink.blob.core.windows.net"
      resource_group_name = azurerm_resource_group.example.name
    }
    "vault" = {
      name                = "privatelink.vaultcore.azure.net"
      resource_group_name = azurerm_resource_group.example.name
    }
  }

  dns_zone_virtual_network_links = {
    "blob-link" = {
      name                  = "blob-vnet-link"
      resource_group_name   = azurerm_resource_group.example.name
      private_dns_zone_key  = "blob"
      private_dns_zone_name = ""
      virtual_network_id    = azurerm_virtual_network.example.id
    }
    "vault-link" = {
      name                  = "vault-vnet-link"
      resource_group_name   = azurerm_resource_group.example.name
      private_dns_zone_key  = "vault"
      private_dns_zone_name = ""
      virtual_network_id    = azurerm_virtual_network.example.id
    }
  }

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

      private_dns_zone_group = {
        name                 = "blob-dns-group"
        private_dns_zone_ids = [module.private_endpoint.private_dns_zone_ids["blob"]]
      }
    }

    "keyvault" = {
      name                = "pe-keyvault"
      resource_group_name = azurerm_resource_group.example.name
      location            = azurerm_resource_group.example.location
      subnet_id           = azurerm_subnet.endpoints.id

      private_service_connection = {
        name                           = "psc-keyvault"
        private_connection_resource_id = azurerm_key_vault.example.id
        subresource_names              = ["vault"]
      }

      private_dns_zone_group = {
        name                 = "vault-dns-group"
        private_dns_zone_ids = [module.private_endpoint.private_dns_zone_ids["vault"]]
      }
    }
  }

  default_tags = {
    Environment = "staging"
    Project     = "example"
  }
}

output "private_endpoint_ids" {
  value = module.private_endpoint.private_endpoint_ids
}

output "dns_zone_ids" {
  value = module.private_endpoint.private_dns_zone_ids
}

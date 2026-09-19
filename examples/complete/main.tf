provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-pe-complete"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-pe-complete"
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

resource "azurerm_subnet" "pls" {
  name                                          = "snet-pls"
  resource_group_name                           = azurerm_resource_group.example.name
  virtual_network_name                          = azurerm_virtual_network.example.name
  address_prefixes                              = ["10.0.2.0/24"]
  private_link_service_network_policies_enabled = false
}

resource "azurerm_virtual_network" "consumer" {
  name                = "vnet-consumer"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "consumer" {
  name                 = "snet-consumer-endpoints"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.consumer.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_storage_account" "example" {
  name                     = "stpecompleteexmpl01"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_key_vault" "example" {
  name                       = "kv-pe-complete-01"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_public_ip" "lb" {
  name                = "pip-lb-pls"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "example" {
  name                = "lb-pls-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

module "private_endpoint" {
  source = "../../"

  # Create private DNS zones
  private_dns_zones = {
    "blob" = {
      name                = "privatelink.blob.core.windows.net"
      resource_group_name = azurerm_resource_group.example.name
      soa_record = {
        email        = "azureprivatedns-host.microsoft.com"
        expire_time  = 2419200
        minimum_ttl  = 10
        refresh_time = 3600
        retry_time   = 300
        ttl          = 3600
      }
    }
    "vault" = {
      name                = "privatelink.vaultcore.azure.net"
      resource_group_name = azurerm_resource_group.example.name
    }
    "custom" = {
      name                = "privatelink.myservice.example.com"
      resource_group_name = azurerm_resource_group.example.name
    }
  }

  # Link DNS zones to VNets
  dns_zone_virtual_network_links = {
    "blob-producer" = {
      name                  = "blob-producer-link"
      resource_group_name   = azurerm_resource_group.example.name
      private_dns_zone_key  = "blob"
      private_dns_zone_name = ""
      virtual_network_id    = azurerm_virtual_network.example.id
    }
    "blob-consumer" = {
      name                  = "blob-consumer-link"
      resource_group_name   = azurerm_resource_group.example.name
      private_dns_zone_key  = "blob"
      private_dns_zone_name = ""
      virtual_network_id    = azurerm_virtual_network.consumer.id
    }
    "vault-producer" = {
      name                  = "vault-producer-link"
      resource_group_name   = azurerm_resource_group.example.name
      private_dns_zone_key  = "vault"
      private_dns_zone_name = ""
      virtual_network_id    = azurerm_virtual_network.example.id
    }
    "custom-producer" = {
      name                  = "custom-producer-link"
      resource_group_name   = azurerm_resource_group.example.name
      private_dns_zone_key  = "custom"
      private_dns_zone_name = ""
      virtual_network_id    = azurerm_virtual_network.example.id
    }
  }

  # Create custom A records
  dns_a_records = {
    "myservice" = {
      name                = "api"
      resource_group_name = azurerm_resource_group.example.name
      zone_key            = "custom"
      ttl                 = 300
      records             = ["10.0.2.10"]
    }
  }

  # Create a Private Link Service
  private_link_services = {
    "myservice" = {
      name                = "pls-myservice"
      resource_group_name = azurerm_resource_group.example.name
      location            = azurerm_resource_group.example.location

      load_balancer_frontend_ip_configuration_ids = [
        azurerm_lb.example.frontend_ip_configuration[0].id
      ]

      auto_approval_subscription_ids = [data.azurerm_client_config.current.subscription_id]
      visibility_subscription_ids    = [data.azurerm_client_config.current.subscription_id]
      enable_proxy_protocol          = false

      nat_ip_configuration = [
        {
          name      = "primary"
          subnet_id = azurerm_subnet.pls.id
          primary   = true
        },
        {
          name      = "secondary"
          subnet_id = azurerm_subnet.pls.id
          primary   = false
        }
      ]
    }
  }

  # Create Private Endpoints
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

      ip_configuration = [
        {
          name               = "blob-ip"
          private_ip_address = "10.0.1.10"
          subresource_name   = "blob"
          member_name        = "blob"
        }
      ]

      custom_network_interface_name = "nic-pe-storage-blob"
    }

    "storage-file" = {
      name                = "pe-storage-file"
      resource_group_name = azurerm_resource_group.example.name
      location            = azurerm_resource_group.example.location
      subnet_id           = azurerm_subnet.endpoints.id

      private_service_connection = {
        name                           = "psc-storage-file"
        private_connection_resource_id = azurerm_storage_account.example.id
        subresource_names              = ["file"]
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

    "pls-consumer" = {
      name                = "pe-pls-consumer"
      resource_group_name = azurerm_resource_group.example.name
      location            = azurerm_resource_group.example.location
      subnet_id           = azurerm_subnet.consumer.id

      private_service_connection = {
        name                           = "psc-pls-consumer"
        private_connection_resource_id = module.private_endpoint.private_link_service_ids["myservice"]
        subresource_names              = []
      }

      private_dns_zone_group = {
        name                 = "custom-dns-group"
        private_dns_zone_ids = [module.private_endpoint.private_dns_zone_ids["custom"]]
      }
    }
  }

  default_tags = {
    Environment = "production"
    Project     = "example"
    CostCenter  = "IT-001"
  }
}

output "private_endpoint_ids" {
  value = module.private_endpoint.private_endpoint_ids
}

output "private_endpoint_ips" {
  value = module.private_endpoint.private_endpoint_ip_addresses
}

output "dns_zone_ids" {
  value = module.private_endpoint.private_dns_zone_ids
}

output "private_link_service_aliases" {
  value = module.private_endpoint.private_link_service_aliases
}

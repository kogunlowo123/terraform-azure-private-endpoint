module "test" {
  source = "../"

  private_endpoints = {
    storage-pe = {
      name                = "pe-storage-test"
      resource_group_name = "rg-private-endpoint-test"
      location            = "eastus2"
      subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-pe"

      private_service_connection = {
        name                           = "psc-storage-test"
        private_connection_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-storage/providers/Microsoft.Storage/storageAccounts/sttest"
        subresource_names              = ["blob"]
        is_manual_connection           = false
      }

      private_dns_zone_group = {
        name                 = "dns-zone-group-storage"
        private_dns_zone_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"]
      }

      tags = {
        environment = "test"
      }
    }
  }

  private_dns_zones = {
    blob = {
      name                = "privatelink.blob.core.windows.net"
      resource_group_name = "rg-private-endpoint-test"
    }
  }

  default_tags = {
    environment = "test"
    managed_by  = "terraform"
  }
}

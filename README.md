# terraform-azure-private-endpoint

Production-ready Terraform module for deploying Azure Private Endpoints with comprehensive support for private DNS zones, DNS zone groups, private link service connections, approval workflows, network interface configuration, and multiple subresources.

## Architecture

```mermaid
flowchart TD
    A[Private Endpoint Module] --> B[Private Endpoints]
    A --> C[Private DNS Zones]
    A --> D[Private Link Services]
    B --> E[Private Service Connections]
    B --> F[DNS Zone Groups]
    B --> G[IP Configurations]
    B --> H[Custom NIC Names]
    C --> I[VNet Links]
    C --> J[A Records]
    D --> K[NAT IP Configurations]
    D --> L[Load Balancer Integration]
    E --> M[Auto-Approved Connections]
    E --> N[Manual Approval Connections]

    style A fill:#0078D4,stroke:#005A9E,color:#FFFFFF
    style B fill:#50E6FF,stroke:#0078D4,color:#000000
    style C fill:#7FBA00,stroke:#5E8C00,color:#FFFFFF
    style D fill:#FFB900,stroke:#FF8C00,color:#000000
    style E fill:#00B7C3,stroke:#008B94,color:#FFFFFF
    style F fill:#7FBA00,stroke:#5E8C00,color:#FFFFFF
    style G fill:#B4A0FF,stroke:#8661C5,color:#000000
    style H fill:#FF9F00,stroke:#CC7F00,color:#000000
    style I fill:#00CC6A,stroke:#009E52,color:#FFFFFF
    style J fill:#00CC6A,stroke:#009E52,color:#FFFFFF
    style K fill:#FF6F61,stroke:#D44942,color:#FFFFFF
    style L fill:#FFD700,stroke:#CCB200,color:#000000
    style M fill:#00B7C3,stroke:#008B94,color:#FFFFFF
    style N fill:#E74856,stroke:#C13239,color:#FFFFFF
```

## Features

- Private Endpoint creation with automatic or manual connection approval
- Private service connections to any Azure PaaS resource or Private Link Service
- Multiple subresource support (blob, file, queue, table, vault, sqlServer, etc.)
- Private DNS Zone management with SOA record configuration
- DNS Zone virtual network links with optional auto-registration
- Custom DNS A record management
- Private Link Service creation with NAT IP configuration
- Static IP assignment for private endpoints via IP configurations
- Custom network interface naming
- Support for resource ID or alias-based connections
- Cross-subscription and cross-tenant connectivity
- Comprehensive tagging support

## Usage

```hcl
module "private_endpoint" {
  source = "path/to/terraform-azure-private-endpoint"

  private_endpoints = {
    "storage-blob" = {
      name                = "pe-storage-blob"
      resource_group_name = "rg-myapp"
      location            = "East US"
      subnet_id           = azurerm_subnet.endpoints.id

      private_service_connection = {
        name                           = "psc-storage-blob"
        private_connection_resource_id = azurerm_storage_account.this.id
        subresource_names              = ["blob"]
      }

      private_dns_zone_group = {
        name                 = "blob-dns-group"
        private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
      }
    }
  }
}
```

## Examples

- [Basic](./examples/basic/) - Simple private endpoint for a storage account
- [Advanced](./examples/advanced/) - Multiple endpoints with DNS zones and VNet links
- [Complete](./examples/complete/) - Full setup with Private Link Service, DNS zones, A records, and consumer endpoints

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| azurerm | >= 3.80.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| private_endpoints | Map of private endpoints to create | `map(object)` | `{}` | no |
| private_dns_zones | Map of private DNS zones | `map(object)` | `{}` | no |
| dns_zone_virtual_network_links | Map of VNet links for DNS zones | `map(object)` | `{}` | no |
| dns_a_records | Map of DNS A records | `map(object)` | `{}` | no |
| private_link_services | Map of Private Link Services | `map(object)` | `{}` | no |
| default_tags | Default tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| private_endpoint_ids | Map of endpoint keys to IDs |
| private_endpoint_ip_addresses | Map of endpoint keys to private IPs |
| private_endpoint_fqdns | Map of endpoint keys to DNS configs |
| private_dns_zone_ids | Map of DNS zone keys to IDs |
| private_dns_zone_names | Map of DNS zone keys to names |
| private_link_service_ids | Map of PLS keys to IDs |
| private_link_service_aliases | Map of PLS keys to aliases |

## License

MIT License - see [LICENSE](./LICENSE) for details.

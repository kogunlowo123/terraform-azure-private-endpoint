locals {
  # Module-level default tags
  module_tags = {
    ManagedBy = "Terraform"
    Module    = "terraform-azure-private-endpoint"
  }

  merged_default_tags = merge(local.module_tags, var.default_tags)

  # Build DNS zone name lookup for records that reference zone_key
  dns_zone_names = {
    for k, v in azurerm_private_dns_zone.this : k => v.name
  }

  # Build DNS zone virtual network link references
  dns_zone_link_zone_names = {
    for k, v in var.dns_zone_virtual_network_links : k =>
    v.private_dns_zone_key != null ? azurerm_private_dns_zone.this[v.private_dns_zone_key].name : v.private_dns_zone_name
  }
}

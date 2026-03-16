output "private_endpoint_ids" {
  description = "Map of private endpoint keys to their IDs."
  value       = { for k, v in azurerm_private_endpoint.this : k => v.id }
}

output "private_endpoint_ip_addresses" {
  description = "Map of private endpoint keys to their private IP addresses."
  value       = { for k, v in azurerm_private_endpoint.this : k => v.private_service_connection[0].private_ip_address }
}

output "private_endpoint_fqdns" {
  description = "Map of private endpoint keys to their custom DNS configurations."
  value       = { for k, v in azurerm_private_endpoint.this : k => v.custom_dns_configs }
}

output "private_endpoint_network_interfaces" {
  description = "Map of private endpoint keys to their network interface IDs."
  value       = { for k, v in azurerm_private_endpoint.this : k => v.network_interface }
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone keys to their IDs."
  value       = { for k, v in azurerm_private_dns_zone.this : k => v.id }
}

output "private_dns_zone_names" {
  description = "Map of private DNS zone keys to their names."
  value       = { for k, v in azurerm_private_dns_zone.this : k => v.name }
}

output "private_dns_zone_virtual_network_link_ids" {
  description = "Map of virtual network link keys to their IDs."
  value       = { for k, v in azurerm_private_dns_zone_virtual_network_link.this : k => v.id }
}

output "private_dns_a_record_ids" {
  description = "Map of A record keys to their IDs."
  value       = { for k, v in azurerm_private_dns_a_record.this : k => v.id }
}

output "private_dns_a_record_fqdns" {
  description = "Map of A record keys to their FQDNs."
  value       = { for k, v in azurerm_private_dns_a_record.this : k => v.fqdn }
}

output "private_link_service_ids" {
  description = "Map of private link service keys to their IDs."
  value       = { for k, v in azurerm_private_link_service.this : k => v.id }
}

output "private_link_service_aliases" {
  description = "Map of private link service keys to their aliases."
  value       = { for k, v in azurerm_private_link_service.this : k => v.alias }
}

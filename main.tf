###############################################################################
# Private DNS Zones
###############################################################################

resource "azurerm_private_dns_zone" "this" {
  for_each = var.private_dns_zones

  name                = each.value.name
  resource_group_name = each.value.resource_group_name

  dynamic "soa_record" {
    for_each = each.value.soa_record != null ? [each.value.soa_record] : []
    content {
      email        = soa_record.value.email
      expire_time  = soa_record.value.expire_time
      minimum_ttl  = soa_record.value.minimum_ttl
      refresh_time = soa_record.value.refresh_time
      retry_time   = soa_record.value.retry_time
      ttl          = soa_record.value.ttl
    }
  }

  tags = merge(local.merged_default_tags, each.value.tags)
}

###############################################################################
# Private DNS Zone Virtual Network Links
###############################################################################

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.dns_zone_virtual_network_links

  name                  = each.value.name
  resource_group_name   = each.value.resource_group_name
  private_dns_zone_name = local.dns_zone_link_zone_names[each.key]
  virtual_network_id    = each.value.virtual_network_id
  registration_enabled  = each.value.registration_enabled

  tags = merge(local.merged_default_tags, each.value.tags)
}

###############################################################################
# Private DNS A Records
###############################################################################

resource "azurerm_private_dns_a_record" "this" {
  for_each = var.dns_a_records

  name                = each.value.name
  zone_name           = each.value.zone_key != null ? azurerm_private_dns_zone.this[each.value.zone_key].name : each.value.zone_name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = merge(local.merged_default_tags, each.value.tags)
}

###############################################################################
# Private Link Services
###############################################################################

resource "azurerm_private_link_service" "this" {
  for_each = var.private_link_services

  name                           = each.value.name
  resource_group_name            = each.value.resource_group_name
  location                       = each.value.location
  auto_approval_subscription_ids = each.value.auto_approval_subscription_ids
  visibility_subscription_ids    = each.value.visibility_subscription_ids
  enable_proxy_protocol          = each.value.enable_proxy_protocol
  fqdns                          = each.value.fqdns
  load_balancer_frontend_ip_configuration_ids = each.value.load_balancer_frontend_ip_configuration_ids

  dynamic "nat_ip_configuration" {
    for_each = each.value.nat_ip_configuration
    content {
      name                       = nat_ip_configuration.value.name
      subnet_id                  = nat_ip_configuration.value.subnet_id
      private_ip_address         = nat_ip_configuration.value.private_ip_address
      private_ip_address_version = nat_ip_configuration.value.private_ip_address_version
      primary                    = nat_ip_configuration.value.primary
    }
  }

  tags = merge(local.merged_default_tags, each.value.tags)
}

###############################################################################
# Private Endpoints
###############################################################################

resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  name                          = each.value.name
  location                      = each.value.location
  resource_group_name           = each.value.resource_group_name
  subnet_id                     = each.value.subnet_id
  custom_network_interface_name = each.value.custom_network_interface_name

  private_service_connection {
    name                              = each.value.private_service_connection.name
    private_connection_resource_id    = each.value.private_service_connection.private_connection_resource_id
    private_connection_resource_alias = each.value.private_service_connection.private_connection_resource_alias
    subresource_names                 = each.value.private_service_connection.subresource_names
    is_manual_connection              = each.value.private_service_connection.is_manual_connection
    request_message                   = each.value.private_service_connection.is_manual_connection ? each.value.private_service_connection.request_message : null
  }

  dynamic "private_dns_zone_group" {
    for_each = each.value.private_dns_zone_group != null ? [each.value.private_dns_zone_group] : []
    content {
      name                 = private_dns_zone_group.value.name
      private_dns_zone_ids = private_dns_zone_group.value.private_dns_zone_ids
    }
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configuration
    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      subresource_name   = ip_configuration.value.subresource_name
      member_name        = ip_configuration.value.member_name
    }
  }

  tags = merge(local.merged_default_tags, each.value.tags)
}

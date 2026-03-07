variable "private_endpoints" {
  description = "Map of private endpoints to create."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    subnet_id           = string

    private_service_connection = object({
      name                              = string
      private_connection_resource_id    = optional(string, null)
      private_connection_resource_alias = optional(string, null)
      subresource_names                 = optional(list(string), [])
      is_manual_connection              = optional(bool, false)
      request_message                   = optional(string, null)
    })

    private_dns_zone_group = optional(object({
      name                 = string
      private_dns_zone_ids = list(string)
    }), null)

    ip_configuration = optional(list(object({
      name               = string
      private_ip_address = string
      subresource_name   = optional(string, null)
      member_name        = optional(string, null)
    })), [])

    custom_network_interface_name = optional(string, null)

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.private_endpoints :
      v.private_service_connection.private_connection_resource_id != null || v.private_service_connection.private_connection_resource_alias != null
    ])
    error_message = "Each private endpoint must specify either private_connection_resource_id or private_connection_resource_alias."
  }
}

variable "private_dns_zones" {
  description = "Map of private DNS zones to create."
  type = map(object({
    name                = string
    resource_group_name = string
    soa_record = optional(object({
      email        = optional(string, "azureprivatedns-host.microsoft.com")
      expire_time  = optional(number, 2419200)
      minimum_ttl  = optional(number, 10)
      refresh_time = optional(number, 3600)
      retry_time   = optional(number, 300)
      ttl          = optional(number, 3600)
    }), null)
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "dns_zone_virtual_network_links" {
  description = "Map of virtual network links for private DNS zones."
  type = map(object({
    name                  = string
    resource_group_name   = string
    private_dns_zone_name = string
    private_dns_zone_key  = optional(string, null)
    virtual_network_id    = string
    registration_enabled  = optional(bool, false)
    tags                  = optional(map(string), {})
  }))
  default = {}
}

variable "dns_a_records" {
  description = "Map of DNS A records to create in private DNS zones."
  type = map(object({
    name                  = string
    resource_group_name   = string
    zone_name             = optional(string, null)
    zone_key              = optional(string, null)
    ttl                   = optional(number, 300)
    records               = list(string)
    tags                  = optional(map(string), {})
  }))
  default = {}
}

variable "private_link_services" {
  description = "Map of private link services to create."
  type = map(object({
    name                           = string
    resource_group_name            = string
    location                       = string
    load_balancer_frontend_ip_configuration_ids = list(string)
    auto_approval_subscription_ids = optional(list(string), [])
    visibility_subscription_ids    = optional(list(string), [])
    enable_proxy_protocol          = optional(bool, false)
    fqdns                          = optional(list(string), [])

    nat_ip_configuration = list(object({
      name                       = string
      subnet_id                  = string
      private_ip_address         = optional(string, null)
      private_ip_address_version = optional(string, "IPv4")
      primary                    = bool
    }))

    tags = optional(map(string), {})
  }))
  default = {}
}

variable "default_tags" {
  description = "Default tags to apply to all resources that support tagging."
  type        = map(string)
  default     = {}
}

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Remove this file is you are not using the private endpoints. 
# Remove the comments to enable the private endpoints.

#---------------------------------------------------------
# Private Link for <<name of resource>> - Default is "false" 
#---------------------------------------------------------
data "azurerm_virtual_network" "vnet" {
  count               = var.enable_private_endpoint && var.existing_virtual_network_name != null ? 1 : 0
  name                = var.existing_virtual_network_name
  resource_group_name = local.resource_group_name
}

data "azurerm_subnet" "snet" {
  count                = var.enable_private_endpoint && var.existing_private_subnet_name != null ? 1 : 0
  name                 = var.existing_private_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.0.name
  resource_group_name  = local.resource_group_name
}

resource "azurerm_private_endpoint" "pep" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = format("%s-private-endpoint", var.workload_name)
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = data.azurerm_subnet.snet.0.id
  tags                = merge({ "Name" = format("%s-private-endpoint", var.workload_name) }, var.add_tags, )

  private_service_connection {
    name                           = "privatelink-primary"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_cognitive_account.openai.id
    subresource_names              = ["account"]
  }
}

#------------------------------------------------------------------
# DNS zone & records for SQL Private endpoints - Default is "false" 
#------------------------------------------------------------------
data "azurerm_private_endpoint_connection" "pip" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = azurerm_private_endpoint.pep.0.name
  resource_group_name = local.resource_group_name
  depends_on          = [azurerm_cognitive_account.openai]
}

resource "azurerm_private_dns_zone" "dns_zone" {
  count               = var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0
  name                = var.environment == "public" ? "privatelink.openai.azure.com" : "privatelink.openai.usgovcloudapi.net"
  resource_group_name = local.resource_group_name
  tags                = merge({ "Name" = format("%s", "Azure-Private-DNS-Zone") }, var.add_tags, )
}

data "azurerm_private_dns_zone" "dns_zone" {
  count               = var.existing_private_dns_zone != null && var.enable_private_endpoint ? 1 : 0
  name                = var.existing_private_dns_zone
  resource_group_name = local.resource_group_name
}

locals {
  private_dns_zone_id = var.existing_private_dns_zone == null ? try(azurerm_private_dns_zone.dns_zone.0.id, null) : try(data.azurerm_private_dns_zone.dns_zone.0.id, null)
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  count                = var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0
  name                 = "vnet-private-zone-link"
  private_dns_zone_id  = local.private_dns_zone_id
  virtual_network_id   = data.azurerm_virtual_network.vnet.0.id
  registration_enabled = true
  tags                 = merge({ "Name" = format("%s", "vnet-private-zone-link") }, var.add_tags, )
}

resource "azurerm_private_dns_a_record" "a_rec" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = azurerm_cognitive_account.openai.name
  private_dns_zone_id = local.private_dns_zone_id
  ttl                 = 300
  records             = [data.azurerm_private_endpoint_connection.pip.0.private_service_connection.0.private_ip_address]
}

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------
# Azure Region Lookup
#----------------------------------------------------------
module "mod_azure_region_lookup" {
  source  = "github.com/POps-Rox/tf-az-overlays-azregionslookup"
  version = "~> 1.0.0"

  azure_region = var.location
}

resource "azurerm_resource_group" "openai-rg" {
  name     = "rg-openai"
  location = module.mod_azure_region_lookup.location_cli
}

resource "azurerm_virtual_network" "openai-vnet" {
  depends_on = [
    azurerm_resource_group.openai-rg
  ]
  name                = "openai-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.openai-rg.name
  address_space       = ["10.0.0.0/16"]
  tags = {
    environment = "test"
  }
}

resource "azurerm_subnet" "openai-snet" {
  depends_on = [
    azurerm_resource_group.openai-rg,
    azurerm_virtual_network.openai-vnet
  ]
  name                 = "openai-snet"
  resource_group_name  = azurerm_resource_group.openai-rg.name
  virtual_network_name = azurerm_virtual_network.openai-vnet.name
  service_endpoints    = ["Microsoft.CognitiveServices"]
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "openai-nsg" {
  depends_on = [
    azurerm_resource_group.openai-rg,
  ]
  name                = "openai-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.openai-rg.name
  tags = {
    environment = "test"
  }
}

resource "azurerm_log_analytics_workspace" "openai-log" {
  depends_on = [
    azurerm_resource_group.openai-rg
  ]
  name                = "openai-log"
  location            = var.location
  resource_group_name = azurerm_resource_group.openai-rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = {
    environment = "test"
  }
}

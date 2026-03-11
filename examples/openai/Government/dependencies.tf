# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------
# Azure Region Lookup
#----------------------------------------------------------
module "mod_azure_region_lookup" {
  source  = "github.com/POps-Rox/tf-az-overlays-azregionslookup"
  version = "~> 1.0.0"

  azure_region = "usgovvirginia"
}

resource "azurerm_resource_group" "openai_rg" {
  name     = "rg-openai"
  location = module.mod_azure_region_lookup.location_cli
}




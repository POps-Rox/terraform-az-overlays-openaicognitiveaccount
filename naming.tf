# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#------------------------------------------------------------
# Azure NoOps Naming - This should be used on all resource naming
#------------------------------------------------------------
data "popsrox_resource_name" "cognitive_account" {
  name          = var.workload_name
  resource_type = "azurerm_cognitive_account"
  prefixes      = [var.org_name, var.use_location_short_name ? module.mod_azure_region_lookup.location_short : var.location]
  suffixes      = compact([var.name_prefix == "" ? null : local.name_prefix, var.environment, local.name_suffix, var.use_naming ? "" : "openai"])
  use_slug      = var.use_naming
  clean_input   = true
  separator     = "-"
}

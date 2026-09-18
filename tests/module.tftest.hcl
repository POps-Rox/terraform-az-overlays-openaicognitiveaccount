# Functional tests for the Azure OpenAI/Cognitive Account overlay.
#
# These use mock_provider and module overrides, so they execute without Azure
# credentials. They exercise module decisions that validate cannot see: naming
# precedence, optional resource conditionals, private DNS ID wiring, tag merging,
# and location passthrough.

mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing"
      name     = "rg-existing"
      location = "eastus"
    }
  }

  mock_data "azurerm_virtual_network" {
    defaults = {
      name = "vnet-openai"
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.Network/virtualNetworks/vnet-openai"
    }
  }

  mock_data "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.Network/virtualNetworks/vnet-openai/subnets/snet-openai"
    }
  }

  mock_data "azurerm_private_endpoint_connection" {
    defaults = {
      private_service_connection = [{
        private_ip_address = "10.0.1.4"
      }]
    }
  }

  mock_data "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com"
    }
  }

  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com"
    }
  }

  mock_resource "azurerm_cognitive_account" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.CognitiveServices/accounts/openai-generated"
      endpoint = "https://openai-generated.openai.azure.com/"
    }
  }
}

mock_provider "azapi" {}

mock_provider "popsrox" {
  mock_data "popsrox_resource_name" {
    defaults = {
      result = "openai-generated"
    }
  }
}

override_module {
  target = module.mod_azure_region_lookup
  outputs = {
    location_cli   = "eastus"
    location_short = "eus"
  }
}

override_module {
  target = module.mod_scaffold_rg
  outputs = {
    resource_group_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-created"
    resource_group_name     = "rg-created"
    resource_group_location = "centralus"
  }
}

variables {
  location                     = "westus2"
  environment                  = "public"
  deploy_environment           = "dev"
  workload_name                = "ai"
  org_name                     = "anoa"
  existing_resource_group_name = "rg-existing"
  custom_subdomain_name        = "openai-test"
  network_acls                 = null
}

run "custom_account_name_overrides_generated_name" {
  command = plan

  variables {
    cognitive_account_custom_name = "openai-custom"
  }

  assert {
    condition     = azurerm_cognitive_account.openai.name == "openai-custom"
    error_message = "cognitive_account_custom_name must override the generated name."
  }
}

run "empty_custom_account_name_falls_through_to_generated_name" {
  command = plan

  variables {
    cognitive_account_custom_name = ""
  }

  assert {
    condition     = azurerm_cognitive_account.openai.name == "openai-generated"
    error_message = "An empty cognitive_account_custom_name must fall through to the generated name."
  }
}

run "disabled_conditionals_are_absent_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_private_endpoint.pep) == 0 && length(azurerm_private_dns_zone.dns_zone) == 0 && length(data.azurerm_private_dns_zone.dns_zone) == 0 && length(azurerm_private_dns_zone_virtual_network_link.vnet_link) == 0 && length(azurerm_private_dns_a_record.a_rec) == 0
    error_message = "Private endpoint and DNS resources/data sources must be absent when enable_private_endpoint is false."
  }

  assert {
    condition     = length(azurerm_management_lock.resource_group_level_lock) == 0
    error_message = "Management locks must be absent when enable_resource_locks is false."
  }
}

run "caller_tags_are_merged_with_defaults" {
  command = plan

  variables {
    add_tags = {
      costCenter = "cc-1234"
      workload   = "override-workload"
    }
  }

  assert {
    condition     = azurerm_cognitive_account.openai.tags["costCenter"] == "cc-1234" && azurerm_cognitive_account.openai.tags["workload"] == "override-workload" && azurerm_cognitive_account.openai.tags["env"] == "dev"
    error_message = "Cognitive account tags must merge default tags and add_tags, with caller tags taking precedence."
  }
}

run "location_passes_through_from_existing_resource_group" {
  command = plan

  assert {
    condition     = azurerm_cognitive_account.openai.location == "eastus"
    error_message = "Cognitive account location must come from the selected resource group lookup."
  }
}

run "enabled_conditionals_create_private_dns_with_ids" {
  command = apply

  variables {
    enable_private_endpoint       = true
    existing_virtual_network_name = "vnet-openai"
    existing_private_subnet_name  = "snet-openai"
    network_acls = {
      default_action = "Deny"
      subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.Network/virtualNetworks/vnet-openai/subnets/snet-openai"
      ip_rules       = ["10.0.1.0/24"]
    }
  }

  assert {
    condition     = length(azurerm_private_endpoint.pep) == 1 && length(azurerm_private_dns_zone.dns_zone) == 1 && length(data.azurerm_private_dns_zone.dns_zone) == 0 && length(azurerm_private_dns_zone_virtual_network_link.vnet_link) == 1 && length(azurerm_private_dns_a_record.a_rec) == 1
    error_message = "Private endpoint, new private DNS zone, VNet link, and A record must be planned when enabled without an existing DNS zone."
  }

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.vnet_link[0].private_dns_zone_id == azurerm_private_dns_zone.dns_zone[0].id && azurerm_private_dns_a_record.a_rec[0].private_dns_zone_id == azurerm_private_dns_zone.dns_zone[0].id
    error_message = "Private DNS VNet link and A record must reference the private DNS zone ID, not the zone name."
  }
}

run "existing_private_dns_zone_name_is_resolved_to_id" {
  command = apply

  variables {
    enable_private_endpoint       = true
    existing_private_dns_zone     = "privatelink.openai.azure.com"
    existing_virtual_network_name = "vnet-openai"
    existing_private_subnet_name  = "snet-openai"
    network_acls = {
      default_action = "Deny"
      subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.Network/virtualNetworks/vnet-openai/subnets/snet-openai"
      ip_rules       = ["10.0.1.0/24"]
    }
  }

  assert {
    condition     = length(azurerm_private_dns_zone.dns_zone) == 0 && length(data.azurerm_private_dns_zone.dns_zone) == 1 && azurerm_private_dns_a_record.a_rec[0].private_dns_zone_id == data.azurerm_private_dns_zone.dns_zone[0].id
    error_message = "An existing private DNS zone name must be resolved through the data source and wired to the A record by ID."
  }
}

run "resource_locks_enable_one_resource_group_lock" {
  command = plan

  variables {
    enable_resource_locks = true
    lock_level            = "ReadOnly"
  }

  assert {
    condition     = length(azurerm_management_lock.resource_group_level_lock) == 1
    error_message = "enable_resource_locks=true must create exactly one resource group lock."
  }

  assert {
    condition     = azurerm_management_lock.resource_group_level_lock[0].scope == data.azurerm_resource_group.rgrp[0].id && azurerm_management_lock.resource_group_level_lock[0].lock_level == "ReadOnly"
    error_message = "The resource group lock must target the selected resource group ID and use the caller-supplied lock level."
  }
}

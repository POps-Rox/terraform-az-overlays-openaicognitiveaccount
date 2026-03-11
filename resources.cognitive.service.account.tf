# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------------
# Azure Cognitive Account
#----------------------------------------------------------------
resource "azurerm_cognitive_account" "openai" {
  name                          = local.cognitive_account_name
  location                      = local.location
  resource_group_name           = local.resource_group_name
  kind                          = "OpenAI"
  custom_subdomain_name         = var.custom_subdomain_name
  sku_name                      = var.sku_name
  public_network_access_enabled = var.public_network_access_enabled

  dynamic "identity" {
    for_each = var.identity_type == null ? [] : ["enabled"]
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids == "UserAssigned" ? var.identity_ids : null
    }
  }

  dynamic "network_acls" {
    for_each = var.network_acls == null ? [] : [var.network_acls]
    iterator = acl

    content {
      default_action = acl.value.default_action
      ip_rules       = acl.value.ip_rules
      virtual_network_rules {
        subnet_id                            = acl.value.subnet_id
        ignore_missing_vnet_service_endpoint = acl.value.ignore_missing_vnet_service_endpoint
      }
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key == null ? [] : [var.customer_managed_key]
    iterator = cmk

    content {
      key_vault_key_id   = cmk.value.key_vault_key_id
      identity_client_id = cmk.value.identity_client_id
    }
  }

  dynamic "storage" {
    for_each = var.storage == null ? [] : [var.storage]
    iterator = st

    content {
      storage_account_id = st.value.storage_account_id
      identity_client_id = st.value.identity_client_id
    }
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

  tags = merge(local.default_tags, var.add_tags)
}

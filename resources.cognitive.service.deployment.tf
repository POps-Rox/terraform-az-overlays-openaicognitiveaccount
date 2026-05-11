# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------------
# Azure Cognitive Account Deployment
#----------------------------------------------------------------
resource "azurerm_cognitive_deployment" "deployment" {
  for_each = { for deployment in var.deployments : deployment.name => deployment }

  name                 = each.key
  cognitive_account_id = azurerm_cognitive_account.openai.id
  rai_policy_name      = each.value.rai_policy_name == "" ? null : each.value.rai_policy_name

  model {
    format  = "OpenAI"
    name    = each.value.model.name
    version = each.value.model.version
  }

  sku {
    name     = try(each.value.scale.type, "Standard")
    tier     = try(each.value.scale.tier, null)
    size     = try(each.value.scale.size, null)
    family   = try(each.value.scale.family, null)
    capacity = try(each.value.scale.capacity, null)
  }
}

# Changelog

## [2.0.0] - 2026-05-12

### ⚠️ Breaking Changes

- Upgraded `hashicorp/azurerm` provider from `~> 3.116` to `~> 4.20`.
- Minimum Terraform CLI version raised from `>= 1.9` to `>= 1.10`.
- Replaced `azurerm_cognitive_deployment.scale {}` block with the 4.x
  `sku {}` block on `azurerm_cognitive_deployment.deployment`:
  ```diff
  -  scale {
  -    type     = each.value.scale.type
  -    tier     = each.value.scale.tier
  -    size     = each.value.scale.size
  -    family   = each.value.scale.family
  -    capacity = each.value.scale.capacity
  -  }
  +  sku {
  +    name     = try(each.value.scale.type, "Standard")
  +    tier     = try(each.value.scale.tier, null)
  +    size     = try(each.value.scale.size, null)
  +    family   = try(each.value.scale.family, null)
  +    capacity = try(each.value.scale.capacity, null)
  +  }
  ```
  The `scale.type` field is mapped to `sku.name` (functionally the
  same string value, e.g. `"Standard"`). The `var.deployments` input
  variable schema is **unchanged** so existing consumers keep working
  without modifying their `terraform.tfvars`.

### Behavior Notes

- The `rai_policy_name` field on `var.deployments[*]` was previously
  declared on the variable but never set on the resource. azurerm 4.x
  supports `rai_policy_name` directly on `azurerm_cognitive_deployment`,
  so this PR wires it through: empty string is treated as null, any
  non-empty value is forwarded to the resource. This restores the
  intended behaviour of the variable.

### Migration Notes for Consumers

- Bump your root `azurerm` provider constraint to `~> 4.20`.
- Ensure Terraform CLI `>= 1.10`.
- Set `ARM_SUBSCRIPTION_ID` env var or `subscription_id` in your
  `provider "azurerm"` block — azurerm 4.x requires it.
- **State migration:** `azurerm_cognitive_deployment` carries the same
  resource ID; the schema change is in-place. `terraform plan` will
  show the `scale` block removed and the `sku` block added but should
  apply as an update without recreation (Azure resource ID is stable).
- Module public input surface (`var.deployments`) is unchanged.

### Added

- `azapi ~> 2.0` provider declaration in `versions.tf` (root + every
  example).
- Complete `terraform {}` block in each example `versions.tf` (was a
  provider-only file previously).

### Removed

- `skip_provider_registration = true` from
  `examples/openai/Government/versions.tf` (argument removed in 4.x).

### Internal

- Standardized `versions.tf` format across root and all examples.
- Bumped `required_version` to `>= 1.10` everywhere.

### Cross-module dependency

This module sources two sibling overlays from GitHub
(`tf-az-overlays-azregionslookup`, `tf-az-overlays-resourcegroup`)
which are still pinned to `azurerm ~> 3.116`. Production consumers
must wait for those overlays' Phase 1 PRs to merge before this
`2.0.0` can be cleanly initialized. Local validation was performed by
patching the cached `versions.tf` of those submodules during
`terraform init -get=false`.

# v1.0.0 - <date>

Added
- Add Something you added

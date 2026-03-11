
###########################
# Global Configuration   ##
###########################

variable "location" {
  description = "Azure region in which instance will be hosted"
  type        = string
}

variable "environment" {
  description = "The Terraform backend environment e.g. public or usgovernment"
  type        = string
}

variable "deploy_environment" {
  description = "Name of the workload's environment"
  type        = string
}

variable "workload_name" {
  description = "Name of the workload_name"
  type        = string
}

variable "org_name" {
  description = "Name of the organization"
  type        = string
}

#############################################
# Cognitive Acount OpenAI Configuration    ##
#############################################

variable "openai_sku_name" {
  description = "(Optional) Specifies the sku name for the Azure OpenAI Service"
  type        = string
  default     = "S0"
}

variable "openai_custom_subdomain_name" {
  description = "(Optional) Specifies the custom subdomain name of the Azure OpenAI Service"
  type        = string
  nullable    = true
  default     = ""
}

variable "openai_public_network_access_enabled" {
  description = "(Optional) Specifies whether public network access is allowed for the Azure OpenAI Service"
  type        = bool
  default     = true
}

variable "openai_deployments" {
  description = "(Optional) Specifies the deployments of the Azure OpenAI Service"
  type = list(object({
    name = string
    model = object({
      name    = string
      version = string
    })
    scale = optional(object({
      type     = optional(string)
      tier     = optional(string)
      size     = optional(string)
      family   = optional(string)
      capacity = optional(number)
    }))
    rai_policy_name = string
  }))
  default = [
    {
      name = "gpt-35-turbo"
      model = {
        name    = "gpt-35-turbo"
        version = "0301"
      }
      scale = {
        type = "Standard"
      }
      rai_policy_name = ""
    }
  ]
}

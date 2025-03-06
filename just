terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0.0"
    }
  }
}

provider "azuread" {
  # Configure Azure AD provider authentication
}

variable "enterprise_app_display_name" {
  description = "Display name of the Enterprise Application"
  type        = string
}

variable "user_principal_names" {
  description = "List of User Principal Names (UPNs) to add as owners"
  type        = list(string)
}

# Get the enterprise application (service principal) by display name
data "azuread_service_principal" "app" {
  display_name = var.enterprise_app_display_name
}

# Get user objects from Azure AD
data "azuread_user" "owners" {
  for_each             = toset(var.user_principal_names)
  user_principal_name = each.key
}

# Add users as service principal owners
resource "azuread_service_principal_owner" "sp_owners" {
  for_each             = data.azuread_user.owners
  service_principal_id = data.azuread_service_principal.app.object_id
  owner_object_id      = each.value.id
}
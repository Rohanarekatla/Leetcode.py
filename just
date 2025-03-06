terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.41.0"
    }
  }
}

provider "azuread" {
  # Authentication using a Service Principal with a Client Secret
  tenant_id     = var.tenant_id
  client_id     = var.client_id
  client_secret = var.client_secret
}

# Variables for Service Principal Authentication
variable "tenant_id" {
  description = "The Azure AD tenant ID"
  type        = string
}

variable "client_id" {
  description = "The client ID (application ID) of the service principal"
  type        = string
}

variable "client_secret" {
  description = "The client secret of the service principal"
  type        = string
  sensitive   = true
}

# Variables for the Enterprise App and User
variable "enterprise_app_object_id" {
  description = "The object ID of the Enterprise Application"
  type        = string
}

variable "user_object_id" {
  description = "The object ID of the user to be added as owner"
  type        = string
}

# Get the enterprise application
data "azuread_service_principal" "enterprise_app" {
  object_id = var.enterprise_app_object_id
}

# Get the user
data "azuread_user" "user" {
  object_id = var.user_object_id
}

# Add the user as an owner to the enterprise app
resource "azuread_service_principal_owner" "app_owner" {
  service_principal_id = data.azuread_service_principal.enterprise_app.object_id
  owner_object_id      = data.azuread_user.user.object_id
}

# Output
output "enterprise_app_name" {
  value = data.azuread_service_principal.enterprise_app.display_name
}

output "user_display_name" {
  value = data.azuread_user.user.display_name
}

output "owner_assignment_id" {
  value = azuread_service_principal_owner.app_owner.id
}
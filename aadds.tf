# Service Principal for Domain Controller Services published application
resource "azuread_service_principal" "aadds" {
  application_id = var.domain_controller_services_id
}

resource "azurerm_resource_provider_registration" "aadds" {
  name = "Microsoft.AAD"
}

# AADDS DC Admin Group and User

resource "azuread_group" "dc_admins" {
  name             = "AAD DC Administrators"
  description      = "AADDS Administrators"
  members          = [azuread_user.dc_admin]
  security_enabled = true
}

resource "random_password" "dc_admin" {
  length = 64
}

resource "azuread_user" "dc_admin" {
  user_principal_name = var.dc_admin_upn
  display_name        = "AADDS DC Administrator"
  password            = random_password.aadds_admin.result
}

# Resource Group

resource "azurerm_resource_group" "aadds" {
  name     = "aadds-rg"
  location = var.location
}

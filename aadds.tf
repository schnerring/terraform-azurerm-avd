# Service Principal for Domain Controller Services published application
resource "azuread_service_principal" "aadds" {
  application_id = var.domain_controller_services_id
}

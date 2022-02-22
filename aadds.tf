# Service Principal for Domain Controller Services published application
resource "azuread_service_principal" "aadds" {
  application_id = var.domain_controller_services_id
}

# Microsoft.AAD Provider Registration

resource "azurerm_resource_provider_registration" "aadds" {
  name = "Microsoft.AAD"
}

# AADDS DC Admin Group and User

resource "azuread_group" "dc_admins" {
  display_name     = "AAD DC Administrators"
  description      = "AADDS Administrators"
  members          = [azuread_user.dc_admin.object_id]
  security_enabled = true
}

resource "random_password" "dc_admin" {
  length = 64
}

resource "azuread_user" "dc_admin" {
  user_principal_name = var.dc_admin_upn
  display_name        = "AADDS DC Administrator"
  password            = random_password.dc_admin.result
}

# Resource Group

resource "azurerm_resource_group" "aadds" {
  name     = "aadds-rg"
  location = var.location
}

# Network Resources

resource "azurerm_virtual_network" "aadds" {
  name                = "aadds-vnet"
  location            = azurerm_resource_group.aadds.location
  resource_group_name = azurerm_resource_group.aadds.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "aadds" {
  name                 = "aadds-snet"
  resource_group_name  = azurerm_resource_group.aadds.name
  virtual_network_name = azurerm_virtual_network.aadds.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "aadds" {
  name                = "aadds-nsg"
  location            = azurerm_resource_group.aadds.location
  resource_group_name = azurerm_resource_group.aadds.name

  # Allow the Azure platform to monitor, manage, and update the managed domain
  # See https://docs.microsoft.com/en-us/azure/active-directory-domain-services/alert-nsg#inbound-security-rules
  security_rule {
    name                       = "AllowRD"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "CorpNetSaw"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowPSRemoting"
    priority                   = 301
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = "AzureActiveDirectoryDomainServices"
    destination_address_prefix = "*"
  }

  # Restrict inbound LDAPS access to specific IP addresses to protect the managed domain from brute force attacks.
  # See https://docs.microsoft.com/en-us/azure/active-directory-domain-services/alert-ldaps#resolution
  # See https://docs.microsoft.com/en-us/azure/active-directory-domain-services/tutorial-configure-ldaps#lock-down-secure-ldap-access-over-the-internet
  # security_rule {
  #   name                       = "AllowLDAPS"
  #   priority                   = 401
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "636"
  #   source_address_prefix      = "<Authorized LDAPS IPs>"
  #   destination_address_prefix = "*"
  # }
}

resource "azurerm_subnet_network_security_group_association" "aadds" {
  subnet_id                 = azurerm_subnet.aadds.id
  network_security_group_id = azurerm_network_security_group.aadds.id
}

# AADDS Managed Domain

resource "azurerm_active_directory_domain_service" "aadds" {
  name                = "aadds"
  location            = azurerm_resource_group.aadds.location
  resource_group_name = azurerm_resource_group.aadds.name

  domain_name = var.domain_name
  sku         = "Standard"

  initial_replica_set {
    subnet_id = azurerm_subnet.aadds.id
  }

  notifications {
    additional_recipients = ["alice@example.com", "bob@example.com"]
    notify_dc_admins      = true
    notify_global_admins  = true
  }

  security {
    sync_kerberos_passwords = true
    sync_ntlm_passwords     = true
    sync_on_prem_passwords  = true
  }

  depends_on = [
    azuread_service_principal.aadds,
    azurerm_resource_provider_registration.aadds,
    azurerm_subnet_network_security_group_association.aadds,
  ]
}

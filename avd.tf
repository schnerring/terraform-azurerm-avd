
# Resource Group

resource "azurerm_resource_group" "avd" {
  name     = "avd-rg"
  location = var.location
}

# Network Resources

resource "azurerm_virtual_network" "avd" {
  name                = "avd-vnet"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  address_space       = ["10.10.0.0/16"]

  # Use AADDS DCs as DNS servers
  dns_servers = azurerm_active_directory_domain_service.aadds.initial_replica_set.0.domain_controller_ip_addresses
}

resource "azurerm_subnet" "avd" {
  name                 = "avd-snet"
  resource_group_name  = azurerm_resource_group.avd.name
  virtual_network_name = azurerm_virtual_network.avd.name
  address_prefixes     = ["10.10.0.0/24"]
}

resource "azurerm_virtual_network_peering" "aadds_to_avd" {
  name                      = "hub-to-avd-peer"
  resource_group_name       = azurerm_resource_group.aadds.name
  virtual_network_name      = azurerm_virtual_network.aadds.name
  remote_virtual_network_id = azurerm_virtual_network.avd.id
}

resource "azurerm_virtual_network_peering" "avd_to_aadds" {
  name                      = "avd-to-aadds-peer"
  resource_group_name       = azurerm_resource_group.avd.name
  virtual_network_name      = azurerm_virtual_network.avd.name
  remote_virtual_network_id = azurerm_virtual_network.aadds.id
}

# Host Pool

locals {
  # Switzerland North is not supported
  avd_location = "West Europe"
}

resource "azurerm_virtual_desktop_host_pool" "avd" {
  name                = "avd-vdpool"
  location            = local.avd_location
  resource_group_name = azurerm_resource_group.avd.name

  type               = "Pooled"
  load_balancer_type = "BreadthFirst"
  friendly_name      = "AVD Host Pool using AADDS"
}

resource "time_rotating" "avd_registration_expiration" {
  # Must be between 1 hour and 30 days
  rotation_days = 29
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd.id
  expiration_date = time_rotating.avd_registration_expiration.rotation_rfc3339
}

# Workspace and App Group

resource "azurerm_virtual_desktop_workspace" "avd" {
  name                = "avd-vdws"
  location            = local.avd_location
  resource_group_name = azurerm_resource_group.avd.name
}

resource "azurerm_virtual_desktop_application_group" "avd" {
  name                = "desktop-vdag"
  location            = local.avd_location
  resource_group_name = azurerm_resource_group.avd.name

  type         = "Desktop"
  host_pool_id = azurerm_virtual_desktop_host_pool.avd.id
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "avd" {
  workspace_id         = azurerm_virtual_desktop_workspace.avd.id
  application_group_id = azurerm_virtual_desktop_application_group.avd.id
}

# Session Host VMs

resource "azurerm_network_interface" "avd" {
  count               = var.avd_host_pool_size
  name                = "avd-nic-${count.index}"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name

  ip_configuration {
    name                          = "avd-ipconf"
    subnet_id                     = azurerm_subnet.avd.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "random_password" "avd_local_admin" {
  length = 64
}

resource "random_id" "avd" {
  count       = length(azurerm_network_interface.avd)
  byte_length = 2
}

# Custom Managed Image
# https://github.com/schnerring/packer-windows-avd
data "azurerm_image" "win11" {
  name                = "win11-21h2-avd-m365-22000.556.220308"
  resource_group_name = "packer-artifacts-rg"
}

resource "azurerm_windows_virtual_machine" "avd" {
  count               = length(random_id.avd)
  name                = "avd-vm-${count.index}-${random_id.avd[count.index].hex}"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name

  size                  = "Standard_D4s_v4"
  license_type          = "Windows_Client" # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/windows-desktop-multitenant-hosting-deployment#verify-your-vm-is-utilizing-the-licensing-benefit
  admin_username        = "avd-local-admin"
  admin_password        = random_password.avd_local_admin.result
  network_interface_ids = [azurerm_network_interface.avd[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Custom Managed Image
  source_image_id = data.azurerm_image.win11.id

  # Official Microsoft Default Image
  #source_image_reference {
  #  publisher = "MicrosoftWindowsDesktop"
  #  offer     = "windows-11"
  #  sku       = "win11-21h2-avd"
  #  version   = "latest"
  #}
}

# AADDS Domain-join

resource "azurerm_virtual_machine_extension" "avd_aadds_join" {
  count                      = length(azurerm_windows_virtual_machine.avd)
  name                       = "aadds-join-vmext"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "Name": "${azurerm_active_directory_domain_service.aadds.domain_name}",
      "OUPath": "${var.avd_ou_path}",
      "User": "${azuread_user.dc_admin.user_principal_name}",
      "Restart": "true",
      "Options": "3"
    }
    SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
    {
      "Password": "${random_password.dc_admin.result}"
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [
    azurerm_virtual_network_peering.aadds_to_avd,
    azurerm_virtual_network_peering.avd_to_aadds
  ]
}

# Register to Host Pool

resource "azurerm_virtual_machine_extension" "avd_register_session_host" {
  count                = length(azurerm_windows_virtual_machine.avd)
  name                 = "register-session-host-vmext"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd[count.index].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.73"

  settings = <<-SETTINGS
    {
      "modulesUrl": "${var.avd_register_session_host_dsc_modules_url}",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "hostPoolName": "${azurerm_virtual_desktop_host_pool.avd.name}",
        "aadJoin": false
      }
    }
    SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
    {
      "properties": {
        "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.avd.token}"
      }
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [azurerm_virtual_machine_extension.avd_aadds_join]
}

# Role-based Access Control

data "azurerm_role_definition" "desktop_virtualization_user" {
  name = "Desktop Virtualization User"
}

resource "azuread_group" "avd_users" {
  display_name     = "AVD Users"
  security_enabled = true
}

resource "azurerm_role_assignment" "avd_users_desktop_virtualization_user" {
  scope              = azurerm_virtual_desktop_application_group.avd.id
  role_definition_id = data.azurerm_role_definition.desktop_virtualization_user.id
  principal_id       = azuread_group.avd_users.id
}

data "azuread_user" "avd_users" {
  for_each            = toset(var.avd_user_upns)
  user_principal_name = each.key
}

resource "azuread_group_member" "avd_users" {
  for_each         = data.azuread_user.avd_users
  group_object_id  = azuread_group.avd_users.id
  member_object_id = each.value.id
}

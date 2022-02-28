variable "domain_controller_services_id" {
  type        = string
  description = "Domain Controller Services Published Application ID."
  # ID for public Azure
  # Other clouds use the ID: 6ba9a5d4-8456-4118-b521-9c5ca10cdf84
  default = "2565bd9d-da50-47d4-8b85-4c97f669dc36"
}

variable "dc_admin_upn" {
  type        = string
  description = "AADDS DC Administrator User Principal Name."
  sensitive   = true
}

variable "location" {
  type        = string
  description = "Azure region for deployments."
}

variable "domain_name" {
  type        = string
  description = "Active Directory domain to use."
}

variable "avd_host_pool_size" {
  type        = number
  description = "Number of session hosts to add to the AVD host pool."
}

variable "avd_ou_path" {
  type        = string
  description = "OU path used to AADDS domain-joining AVD session hosts."
  default     = ""
}

variable "avd_register_session_host_dsc_modules_url" {
  type        = string
  description = "URL to .zip file containing DSC configuration to register AVD session hosts to AVD host pool."
  # Get list of releases used by Azure Portal
  # https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts?restype=container&comp=list&prefix=Configuration
  # Development version from master branch
  # https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip
  default = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_02-23-2022.zip"
}

variable "avd_user_upns" {
  type        = list(string)
  description = "List of user UPNs authorized to access AVD."
  default     = []
}

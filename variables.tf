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

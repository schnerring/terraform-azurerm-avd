output "dc_admin_upn" {
  description = "AADDS DC Administrator User Principal Name."
  value       = azuread_user.dc_admin.user_principal_name
  sensitive   = true
}

output "dc_admin_password" {
  description = "AADDS DC Administrator Password."
  value       = random_password.dc_admin.result
  sensitive   = true
}

# output "avd_local_admin_username" {
#   description = "AVD Local Admin Username."
#   value       = azuread_user.dc_admin.user_principal_name
#   sensitive   = true
# }

output "avd_local_admin_password" {
  description = "AVD Local Admin Password."
  value       = random_password.avd_local_admin.result
  sensitive   = true
}

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

# aadds-wvd-terraform

Terraform sample containing Azure Active Directory Domain Services (AADDS) and Azure Virtual Desktop (AVD) deployments.

## Prerequisites

- Active Azure subscription
- [Azure Active Directory (Azure AD / AAD) tenant](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-create-new-tenant)
- [Authenticate to Azure with Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure)

## Variables

| Name           | Example              |
| -------------- | -------------------- |
| `dc_admin_upn` | dc-admin@example.com |
| `location`     | Switzerland North    |
| `domain_name`  | aadds.example.com    |

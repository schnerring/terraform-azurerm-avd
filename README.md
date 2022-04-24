# aadds-wvd-terraform

Terraform sample containing Azure Active Directory Domain Services (AADDS) and Azure Virtual Desktop (AVD) deployments.

Read about the thoughts going into this on my blog:

- [Set Up Azure Active Directory Domain Services (AADDS) With Terraform](https://schnerring.net/blog/set-up-azure-active-directory-domain-services-aadds-with-terraform-updated/)
- [Deploy Azure Virtual Desktop (AVD) Using Terraform and Azure Active Directory Domain Services (AADDS)](https://schnerring.net/blog/deploy-azure-virtual-desktop-avd-using-terraform-and-azure-active-directory-domain-services-aadds/)

## Prerequisites

- Active Azure subscription
- [Azure Active Directory (Azure AD / AAD) tenant](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-create-new-tenant)
- [Authenticate to Azure with Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure)

## Variables

| Name                 | Example                                    |
| -------------------- | ------------------------------------------ |
| `dc_admin_upn`       | `dc-admin@example.com`                     |
| `location`           | `Switzerland North`                        |
| `domain_name`        | `aadds.example.com`                        |
| `avd_host_pool_size` | `2`                                        |
| `avd_user_upns`      | `["alice@example.com", "bob@example.com"]` |

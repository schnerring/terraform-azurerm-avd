terraform {
  required_version = ">= 1.1.6"

  required_providers {
    azuread = {
      source  = "azuread"
      version = ">= 2.18.0"
    }

    azurerm = {
      source  = "azurerm"
      version = ">= 2.97.0"
    }

    random = {
      source  = "random"
      version = ">= 3.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

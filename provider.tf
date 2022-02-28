terraform {
  required_version = ">= 1.1.6"

  required_providers {
    azuread = {
      source  = "azuread"
      version = ">= 2.18.0"
    }

    azurerm = {
      source  = "azurerm"
      version = ">= 2.98.0"
    }

    random = {
      source  = "random"
      version = ">= 3.1.0"
    }

    time = {
      source  = "time"
      version = ">= 0.7.2"
    }
  }
}

provider "azurerm" {
  features {}
}

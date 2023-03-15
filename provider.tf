terraform {
  required_version = ">= 1.4.0"

  required_providers {
    azuread = {
      source  = "azuread"
      version = "~> 2.36.0"
    }

    azurerm = {
      source  = "azurerm"
      version = "~> 3.47.0"
    }

    random = {
      source  = "random"
      version = "~> 3.4.0"
    }

    time = {
      source  = "time"
      version = "~> 0.9.1"
    }
  }
}

provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.5"
    }
  }
  required_version = ">= 1.13.0"
}

provider "azuread" {
}
  
provider "azurerm" {
  features {}
}
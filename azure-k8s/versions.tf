terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.45.1"
    }

    random = {
      source  = "hashicorp/random"
      version = ">=3.0.1"
    }
  }
}

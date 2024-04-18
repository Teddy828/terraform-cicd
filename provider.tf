variable "client_secret" {
}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.99.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "de61f224-9a69-4ede-8273-5bcef854dc20"
  tenant_id = "2fa430c4-fd7e-4dfe-996c-46fc2cda44f8"
  client_id = "f8bebf6d-2f91-4686-8ca6-823047a2a29f"
  client_secret = var.client_secret
  features {}
}
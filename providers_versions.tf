terraform {
  cloud {
    organization = "CONIX"

    workspaces {
      name = "AVX-TGW-connect"
    }
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.46.0"
    }

    aviatrix = {
      source  = "aviatrixsystems/aviatrix"
      version = "2.22.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "4.17.1"
    }
  }
}

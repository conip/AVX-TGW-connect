provider "aviatrix" {
  controller_ip = var.controller_ip
  username      = var.avx_username
  password      = var.avx_controller_admin_password
}

provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  # credentials passed via TF Cloud ENV
  features {}
}

variable "controller_ip" {
  type = string
}

variable "avx_username" {
  type    = string
  default = "admin"
}

variable "avx_controller_admin_password" {
  type = string
}

variable "avx_ctrl_account_alicloud" {
  type        = string
  description = "account name of ALI CLOUD defined in EU Controller"
}

variable "avx_ctrl_account_aws" {
  type        = string
  description = "account name of AWS CLOUD defined in EU Controller"
}

variable "avx_ctrl_account_azure" {
  type        = string
  description = "account name of AZURE CLOUD defined in EU Controller"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "ssh_key" {
  type        = string
  description = "SSH key for the ubuntu VMs"
}
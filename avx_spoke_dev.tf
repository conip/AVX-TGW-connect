module "aws_dev_spoke_1" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  name            = "BL4-AVX-dev-spoke-1"
  cloud           = "aws"
  region          = "eu-central-1"
  cidr            = "10.91.0.0/16"
  account         = var.avx_ctrl_account_aws
  transit_gw      = module.aws_transit_eu_1.transit_gateway.gw_name
  security_domain = "dev"
  tags = {
    Owner = "pkonitz"
  }
  depends_on = [
    aviatrix_segmentation_security_domain.segment_dev
  ]
}

data "aviatrix_vpc" "avx_spoke_1_vpc" {
  name                = module.aws_dev_spoke_1.vpc.name
  route_tables_filter = "private"
  depends_on = [
    module.aws_dev_spoke_1
  ]
}

module "avx_spoke_dev_vm" {
  source = "git::https://github.com/fkhademi/terraform-aws-instance-module.git"

  name      = "BL4-avx-spoke-dev"
  region    = var.aws_region
  vpc_id    = data.aviatrix_vpc.avx_spoke_1_vpc.vpc_id
  subnet_id = data.aviatrix_vpc.avx_spoke_1_vpc.subnets[0].subnet_id
  ssh_key   = var.ssh_key
  public_ip = false
  depends_on = [
    module.aws_dev_spoke_1
  ]
}


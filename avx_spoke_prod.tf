module "aws_prod_spoke_1" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  name            = "BL4-AVX-prod-spoke-1"
  cloud           = "aws"
  region          = "eu-central-1"
  cidr            = "10.81.0.0/16"
  account         = var.avx_ctrl_account_aws
  transit_gw      = module.aws_transit_eu_1.transit_gateway.gw_name
  network_domain = "prod"
  tags = {
    Owner = "pkonitz"
  }
  depends_on = [
    aviatrix_segmentation_network_domain.segment_prod
  ]
}

data "aviatrix_vpc" "avx_spoke_2_vpc" {
  name                = module.aws_prod_spoke_1.vpc.name
  route_tables_filter = "private"
  depends_on = [
    module.aws_prod_spoke_1
  ]
}

module "avx_spoke_prod_vm" {
  source = "git::https://github.com/fkhademi/terraform-aws-instance-module.git"

  name      = "BL4-avx-spoke-prod"
  region    = var.aws_region
  vpc_id    = data.aviatrix_vpc.avx_spoke_2_vpc.vpc_id
  subnet_id = data.aviatrix_vpc.avx_spoke_2_vpc.subnets[0].subnet_id
  ssh_key   = var.ssh_key
  public_ip = false
  depends_on = [
    module.aws_prod_spoke_1
  ]
}

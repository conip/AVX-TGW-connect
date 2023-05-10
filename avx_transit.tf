#---------------------------------------------------------- EUROPE ----------------------------------------------------------
module "aws_transit_eu_1" {
  source              = "terraform-aviatrix-modules/mc-transit/aviatrix"
  name                = "BL4-AWS-trans"
  cloud               = "aws"
  region              = "eu-central-1"
  cidr                = "10.77.0.0/23"
  account             = var.avx_ctrl_account_aws
  bgp_ecmp            = true
  enable_segmentation = "true"
  local_as_number     = "65101"
  tags = {
    Owner = "pkonitz"
  }
}

resource "aviatrix_segmentation_network_domain" "segment_prod" {
  domain_name = "prod"
}

resource "aviatrix_segmentation_network_domain" "segment_dev" {
  domain_name = "dev"
}

resource "aviatrix_transit_external_device_conn" "dev_conn_1" {
  vpc_id                   = module.aws_transit_eu_1.transit_gateway.vpc_id
  connection_name          = "dev-conn-1"
  gw_name                  = module.aws_transit_eu_1.transit_gateway.gw_name
  connection_type          = "bgp"
  tunnel_protocol          = "GRE"
  remote_gateway_ip        = "10.119.100.1,10.119.100.2"
  bgp_local_as_num         = "65101"
  bgp_remote_as_num        = "64512"
  local_tunnel_cidr        = "169.254.101.1/30,169.254.102.1/30"
  remote_tunnel_cidr       = "169.254.101.2/30,169.254.102.2/30"
  enable_edge_segmentation = false
}

resource "aviatrix_transit_external_device_conn" "prod_conn_1" {
  vpc_id                   = module.aws_transit_eu_1.transit_gateway.vpc_id
  connection_name          = "prod-conn-1"
  gw_name                  = module.aws_transit_eu_1.transit_gateway.gw_name
  connection_type          = "bgp"
  tunnel_protocol          = "GRE"
  remote_gateway_ip        = "10.119.200.1,10.119.200.2"
  bgp_local_as_num         = "65101"
  bgp_remote_as_num        = "64512"
  local_tunnel_cidr        = "169.254.201.1/30,169.254.202.1/30"
  remote_tunnel_cidr       = "169.254.201.2/30,169.254.202.2/30"
  enable_edge_segmentation = false
}

resource "aviatrix_segmentation_network_domain_association" "segment_association_dev_conn_1" {
  transit_gateway_name = module.aws_transit_eu_1.transit_gateway.gw_name
  network_domain_name  = aviatrix_segmentation_network_domain.segment_dev.domain_name
  attachment_name      = aviatrix_transit_external_device_conn.dev_conn_1.connection_name
  depends_on = [
    aviatrix_transit_external_device_conn.dev_conn_1,
    module.aws_transit_eu_1
  ]
}

resource "aviatrix_segmentation_network_domain_association" "segment_association_prod_conn_1" {
  transit_gateway_name = module.aws_transit_eu_1.transit_gateway.gw_name
  network_domain_name  = aviatrix_segmentation_network_domain.segment_prod.domain_name
  attachment_name      = aviatrix_transit_external_device_conn.prod_conn_1.connection_name
  depends_on = [
    aviatrix_transit_external_device_conn.prod_conn_1,
    module.aws_transit_eu_1
  ]
}




data "aviatrix_vpc" "aws_transit_eu_1" {
  name                = module.aws_transit_eu_1.vpc.name
  route_tables_filter = "public"
  depends_on = [
    module.aws_transit_eu_1
  ]
}

# output "vpc_routing_tables" {
#   value = data.aviatrix_vpc.aws_transit_eu_1.route_tables[0]
# }

resource "aws_route" "TrGW_route_to_TGW" {
  route_table_id         = data.aviatrix_vpc.aws_transit_eu_1.route_tables[0]
  destination_cidr_block = "10.119.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.TGW.id
  depends_on = [
    module.aws_transit_eu_1,
    aws_ec2_transit_gateway.TGW
  ]
}

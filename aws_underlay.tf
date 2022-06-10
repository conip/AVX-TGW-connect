#====================================================== AWS ======================================================

locals {
  vpc_rt_to_tgw = [
    {
      cidr_block = "10.0.0.0/8"
      tgw_id     = aws_ec2_transit_gateway.TGW.id
    },
    {
      cidr_block = "172.16.0.0/12"
      tgw_id     = aws_ec2_transit_gateway.TGW.id
    }
  ]
}


variable "tgw_cidr" {
  default = "10.119.0.0/16"
}

resource "aws_ec2_transit_gateway" "TGW" {
  description                     = "AWS TGW"
  amazon_side_asn                 = "64512"
  default_route_table_association = "disable"
  transit_gateway_cidr_blocks     = [var.tgw_cidr]
  tags = {
    Name = "TGW-BL4-native"
    Blog = "post4"
  }
}
resource "aws_ec2_transit_gateway_route_table" "TGW_RT_AVX" {
  transit_gateway_id = aws_ec2_transit_gateway.TGW.id
  tags = {
    Name = "BL4-RT-AVX-underlay"
    Blog = "post4"
  }
}

resource "aws_ec2_transit_gateway_route_table" "TGW_RT_PROD" {
  transit_gateway_id = aws_ec2_transit_gateway.TGW.id
  tags = {
    Name = "BL4-RT-PROD"
    Blog = "post4"
  }
}

resource "aws_ec2_transit_gateway_route_table" "TGW_RT_DEV" {
  transit_gateway_id = aws_ec2_transit_gateway.TGW.id
  tags = {
    Name = "BL4-RT-DEV"
    Blog = "post4"
  }
}

locals {
  # underlay_subnets_to_attach_1 = tomap({
  #   for pub_sub in data.aviatrix_vpc.aws_transit_eu_1.public_subnets :
  #   pub_sub.name => pub_sub.subnet_id if length(regexall("mgmt", pub_sub.name))>0
  # })
  underlay_subnets_to_attach_2 = tolist([
    for subnet in data.aviatrix_vpc.aws_transit_eu_1.public_subnets :
    subnet.subnet_id if length(regexall("mgmt", subnet.name)) > 0
  ])
}

# output "test1" {
#   value = local.underlay_subnets_to_attach_1
# }
# output "test2" {
#   value = local.underlay_subnets_to_attach_2
# }

resource "aws_ec2_transit_gateway_vpc_attachment" "TGW_attachment_AVIATRIX_VPC" {
  # we want to attach TGW in subnets where eth0 of both AVX GW sits so mgmt subnets 
  #subnet_ids                                      = [data.aviatrix_vpc.aws_transit_eu_1.public_subnets[0].subnet_id, data.aviatrix_vpc.aws_transit_eu_1.public_subnets[2].subnet_id]
  subnet_ids                                      = local.underlay_subnets_to_attach_2
  transit_gateway_id                              = aws_ec2_transit_gateway.TGW.id
  vpc_id                                          = module.aws_transit_eu_1.transit_gateway.vpc_id
  transit_gateway_default_route_table_association = false
  tags = {
    Name = "BL4-AVX-VPC"
    Blog = "post4"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "RT_ass_AVX_underlay" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.TGW_attachment_AVIATRIX_VPC.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW_RT_AVX.id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "propagation_VPC_AVX_underlay" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.TGW_attachment_AVIATRIX_VPC.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW_RT_AVX.id
}

#-------------------------------------- update - DEV

resource "aws_ec2_transit_gateway_connect" "connect_DEV" {
  transport_attachment_id                         = aws_ec2_transit_gateway_vpc_attachment.TGW_attachment_AVIATRIX_VPC.id
  transit_gateway_id                              = aws_ec2_transit_gateway.TGW.id
  transit_gateway_default_route_table_association = false
  tags = {
    Name = "BL4-GRE-DEV"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "RT_ass_connect_to_RT-DEV" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_connect.connect_DEV.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW_RT_DEV.id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "propagation_Connect_to_RT-DEV" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_connect.connect_DEV.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW_RT_DEV.id
}

resource "aws_ec2_transit_gateway_connect_peer" "BL4-DEV-AVX-primary" {
  peer_address                  = module.aws_transit_eu_1.transit_gateway.private_ip
  transit_gateway_address       = "10.119.100.1"
  inside_cidr_blocks            = ["169.254.101.0/29"]
  bgp_asn                       = "65101"
  transit_gateway_attachment_id = aws_ec2_transit_gateway_connect.connect_DEV.id
  tags = {
    Name = "BL4-DEV-AVX-primary"
  }
}

resource "aws_ec2_transit_gateway_connect_peer" "BL4-DEV-AVX-ha" {
  peer_address                  = module.aws_transit_eu_1.transit_gateway.ha_private_ip
  transit_gateway_address       = "10.119.100.2"
  inside_cidr_blocks            = ["169.254.102.0/29"]
  bgp_asn                       = "65101"
  transit_gateway_attachment_id = aws_ec2_transit_gateway_connect.connect_DEV.id
  tags = {
    Name = "BL4-DEV-AVX-ha"
  }
}

#-------------------------------------- update - PROD

resource "aws_ec2_transit_gateway_connect" "connect_PROD" {
  transport_attachment_id                         = aws_ec2_transit_gateway_vpc_attachment.TGW_attachment_AVIATRIX_VPC.id
  transit_gateway_id                              = aws_ec2_transit_gateway.TGW.id
  transit_gateway_default_route_table_association = false
  tags = {
    Name = "BL4-GRE-PROD"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "RT_ass_connect_to_RT-PROD" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_connect.connect_PROD.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW_RT_PROD.id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "propagation_Connect_to_RT-PROD" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_connect.connect_PROD.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW_RT_PROD.id
}

resource "aws_ec2_transit_gateway_connect_peer" "BL4-PROD-AVX-primary" {
  peer_address                  = module.aws_transit_eu_1.transit_gateway.private_ip
  transit_gateway_address       = "10.119.200.1"
  inside_cidr_blocks            = ["169.254.201.0/29"]
  bgp_asn                       = "65101"
  transit_gateway_attachment_id = aws_ec2_transit_gateway_connect.connect_PROD.id
  tags = {
    Name = "BL4-PROD-AVX-primary"
  }
}

resource "aws_ec2_transit_gateway_connect_peer" "BL4-PROD-AVX-ha" {
  peer_address                  = module.aws_transit_eu_1.transit_gateway.ha_private_ip
  transit_gateway_address       = "10.119.200.2"
  inside_cidr_blocks            = ["169.254.202.0/29"]
  bgp_asn                       = "65101"
  transit_gateway_attachment_id = aws_ec2_transit_gateway_connect.connect_PROD.id
  tags = {
    Name = "BL4-PROD-AVX-ha"
  }
}
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



resource "aws_ec2_transit_gateway" "TGW" {
  description                     = "AWS TGW"
  amazon_side_asn                 = "64512"
  default_route_table_association = "disable"
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

resource "aws_ec2_transit_gateway_vpc_attachment" "TGW_attachment_AVIATRIX_VPC" {
  subnet_ids                                      = [data.aviatrix_vpc.aws_transit_eu_1.subnets[4].subnet_id, data.aviatrix_vpc.aws_transit_eu_1.subnets[6].subnet_id]
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
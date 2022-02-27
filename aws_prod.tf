#--------------------------------------------------------- AWS PROD --------------------------------------------------------
resource "aws_vpc" "PROD" {
  cidr_block       = "10.82.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name    = "BL4-AWS-prod-spoke-2"
    Segment = "PROD"
    Blog    = "post4"
  }
}

resource "aws_subnet" "PROD_subnet_0" {
  vpc_id     = aws_vpc.PROD.id
  cidr_block = "10.82.0.0/24"

  tags = {
    Name    = "PROD-sub-0"
    Segment = "PROD"
    Blog    = "post4"
  }
}
resource "aws_internet_gateway" "prod_int_gw" {
  vpc_id = aws_vpc.PROD.id
}

resource "aws_route_table" "RT_PROD" {
  vpc_id = aws_vpc.PROD.id

  dynamic "route" {
    for_each = local.vpc_rt_to_tgw
    content {
      cidr_block         = route.value.cidr_block
      transit_gateway_id = route.value.tgw_id
    }
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod_int_gw.id
  }
  tags = {
    Name    = "VPC-RT-PROD"
    Segment = "RED"
    Blog    = "post4"
  }
}

resource "aws_route_table_association" "rt_assoc_PROD" {
  subnet_id      = aws_subnet.PROD_subnet_0.id
  route_table_id = aws_route_table.RT_PROD.id
}
resource "aws_ec2_transit_gateway_vpc_attachment" "PROD_to_TGW" {
  subnet_ids                                      = [aws_subnet.PROD_subnet_0.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.TGW.id
  vpc_id                                          = aws_vpc.PROD.id
  transit_gateway_default_route_table_association = false
  tags = {
    Name    = "PROD-to-TGW"
    Segment = "RED"
    Blog    = "post4"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "RT_ass_PROD" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.PROD_to_TGW.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW_RT_PROD.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "PROD_propagation_vpc_prod" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.PROD_to_TGW.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW_RT_PROD.id
}

module "aws_srv_prod" {
  source = "git::https://github.com/fkhademi/terraform-aws-instance-module.git"

  name      = "BL4-aws-prod"
  region    = var.aws_region
  vpc_id    = aws_vpc.PROD.id
  subnet_id = aws_subnet.PROD_subnet_0.id
  ssh_key   = var.ssh_key
  public_ip = true
  depends_on = [
    aws_internet_gateway.prod_int_gw
  ]
}


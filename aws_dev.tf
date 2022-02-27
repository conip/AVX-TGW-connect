#--------------------------------------------------------- AWS DEV --------------------------------------------------------
resource "aws_vpc" "DEV" {
  cidr_block       = "10.92.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name    = "BL4-AWS-dev-spoke-2"
    Segment = "DEV"
    Blog    = "post4"
  }
}

resource "aws_subnet" "DEV_subnet_0" {
  vpc_id     = aws_vpc.DEV.id
  cidr_block = "10.92.0.0/24"

  tags = {
    Name    = "DEV-sub-0"
    Segment = "DEV"
    Blog    = "post4"
  }
}

resource "aws_internet_gateway" "dev_int_gw" {
  vpc_id = aws_vpc.DEV.id
}

resource "aws_route_table" "RT_DEV" {
  vpc_id = aws_vpc.DEV.id

  dynamic "route" {
    for_each = local.vpc_rt_to_tgw
    content {
      cidr_block         = route.value.cidr_block
      transit_gateway_id = route.value.tgw_id
    }
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_int_gw.id
  }
  tags = {
    Name    = "BL4-RT-VPC-DEV"
    Segment = "DEV"
    Blog    = "post4"
  }
}

resource "aws_route_table_association" "rt_assoc_DEV" {
  subnet_id      = aws_subnet.DEV_subnet_0.id
  route_table_id = aws_route_table.RT_DEV.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "DEV_to_TGW" {
  subnet_ids                                      = [aws_subnet.DEV_subnet_0.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.TGW.id
  vpc_id                                          = aws_vpc.DEV.id
  transit_gateway_default_route_table_association = false
  tags = {
    Name    = "BL4-DEV-to-TGW"
    Segment = "DEV"
    Blog    = "post4"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "RT_ass_DEV" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.DEV_to_TGW.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW_RT_DEV.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "DEV_propagation_vpc_dev" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.DEV_to_TGW.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW_RT_DEV.id
}


module "aws_srv_dev" {
  source = "git::https://github.com/fkhademi/terraform-aws-instance-module.git"

  name      = "BL4-aws-dev"
  region    = var.aws_region
  vpc_id    = aws_vpc.DEV.id
  subnet_id = aws_subnet.DEV_subnet_0.id
  ssh_key   = var.ssh_key
  public_ip = true
  depends_on = [
    aws_internet_gateway.dev_int_gw
  ]
}


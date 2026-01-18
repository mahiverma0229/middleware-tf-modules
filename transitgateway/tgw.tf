#Transit Gateway
resource "aws_ec2_transit_gateway" "tgw" {
  amazon_side_asn = var.amazon_side_asn 
  auto_accept_shared_attachments = var.auto_accept_shared_attachments 
  default_route_table_association = var.default_route_table_association
  default_route_table_propagation = var.default_route_table_propagation 
  dns_support = var.dns_support
  vpn_ecmp_support = var.vpn_ecmp_support
  tags = merge(
    {
    "Name" = "${var.name_prefix}-${var.cluster_id}-${var.namespace_id}-tgw"
    }
  )
}

locals{
## Cluster private subnet variable
   region = split("-", var.aws_region)
   cluster_private_subnets = join( "-", [var.connect_cluster_env_name,local.region[0],"*","private"])
}

#Fetching Private Subnet IDs for the Cluster VPC
 data "aws_subnets" "cluster_vpc_private_subnet" {
  
   filter {
    name   = "vpc-id"
    values = [var.connect_cluster_tga_vpc_id]
  }

   filter {
    name   = "tag:Name"
    values = ["*-private-*",local.cluster_private_subnets]
  }
 }

 locals{
  ## Middleware + Cluster VPC
  tga_subnet_ids = var.tgw_secondary ? var.tgw_attach_middleware ? [var.subnet_ids] : [] : var.tgw_attach_middleware ? [var.subnet_ids, data.aws_subnets.cluster_vpc_private_subnet.ids] : [data.aws_subnets.cluster_vpc_private_subnet.ids]
  tga_vpc_id = var.tgw_secondary ? var.tgw_attach_middleware ? [var.vpc_id] : [] : var.tgw_attach_middleware ? [var.vpc_id, var.connect_cluster_tga_vpc_id] : [var.connect_cluster_tga_vpc_id] 
 }

#Transit Gateway Attachments
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attach" {
  count = length(local.tga_vpc_id)
  subnet_ids         = local.tga_subnet_ids[count.index]          
  transit_gateway_id = one(aws_ec2_transit_gateway.tgw[*].id)
  vpc_id             = local.tga_vpc_id[count.index]
  dns_support = var.dns_support
  tags = merge(
    {
    "Name" = "${var.name_prefix}-${var.cluster_id}-${var.namespace_id}-tg-attachment"
    }
  )
  transit_gateway_default_route_table_association = var.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = var.transit_gateway_default_route_table_propagation
}

#transit gateway route table
resource "aws_ec2_transit_gateway_route_table" "tgw_rtb" {
  transit_gateway_id = one(aws_ec2_transit_gateway.tgw[*].id)
  tags = merge(
    {
    "Name" = "${var.name_prefix}-${var.cluster_id}-${var.namespace_id}-tg-rtb"
    }
  )
}

#transit gateway association
resource "aws_ec2_transit_gateway_route_table_association" "tgw_rtb_assoc" {
  count = length(local.tga_vpc_id)
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_attach[count.index].id
  transit_gateway_route_table_id = one(aws_ec2_transit_gateway_route_table.tgw_rtb[*].id)
}

#transit gateway propagation
resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_rtb_prop" {
  count = length(local.tga_vpc_id)
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_attach[count.index].id
  transit_gateway_route_table_id = one(aws_ec2_transit_gateway_route_table.tgw_rtb[*].id)
}

# #transit gateway route
# resource "aws_ec2_transit_gateway_route" "tgw_route" {
#   destination_cidr_block         = "0.0.0.0/0"
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_attach.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rtb.id
# }

# Private Route table entry for cluster vpc. This below data-sources and resource creation is skipped during secondary region
data "aws_vpc" "selected_cluster_vpc" {
  #count = var.tgw_secondary ? 0 : 2
  count  = var.tgw_secondary ? 0 : var.old_subnets_toggle ? 2 : 3
  
  id = var.connect_cluster_tga_vpc_id
}

data "aws_route_tables" "selected_cluster_vpc_route_tables" {
  vpc_id                    = var.connect_cluster_tga_vpc_id
  filter {
    name   = "tag:Name"
    values = ["*-private-*"]
  }
}

resource "aws_route" "selected_cluster_tgw_private_dest" {
  count = var.tgw_secondary ? 0 : var.selected_cluster_vpc_num_private_subnets

  route_table_id            = element(data.aws_route_tables.selected_cluster_vpc_route_tables.ids, count.index)
  destination_cidr_block    = data.aws_vpc.middleware_vpc.cidr_block #This should contain middleware vpc cidr range
  transit_gateway_id        = aws_ec2_transit_gateway.tgw.id
}

# Private Route table entry for middleware vpc
data "aws_vpc" "middleware_vpc" {
  id = var.vpc_id
}

data "aws_route_tables" "middleware_vpc_route_tables" {
  vpc_id                    = var.vpc_id
  filter {
    name   = "tag:Name"
    values = ["*-private-*"]
  }
}

resource "aws_route" "middleware_vpc_tgw_private_dest" {
  #count = length(data.aws_route_tables.middleware_vpc_route_tables.ids)
  count = var.tgw_secondary ? 0 : var.tgw_attach_middleware ? var.old_subnets_toggle ? 2 : 3 : 0
  
  route_table_id            = element(data.aws_route_tables.middleware_vpc_route_tables.ids, count.index)
  destination_cidr_block    = data.aws_vpc.selected_cluster_vpc[count.index].cidr_block ##This should contain cluster vpc cidr range
  transit_gateway_id        = aws_ec2_transit_gateway.tgw.id
}

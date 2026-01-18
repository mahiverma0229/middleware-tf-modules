


locals {
## Cluster private subnet variable
   region = split("-", var.aws_region)
   env_name = flatten([
    for vpcname in var.gsp_cluster_vpc_name : [
      for vpcid in var.gsp_cluster_vpc_id : {
        vpcid = vpcid
        vpcname = join( "-",[vpcname,local.region[0],"*","private"])
      }]
   ]) 
}

# data source for target GSP vpc
data "aws_vpc" "gsp_vpc_id" {
  for_each = toset(var.gsp_cluster_vpc_id)
  id = each.value
}

 
#Fetching Private Subnet IDs for each GSP vpc
 data "aws_subnets" "gsp_vpc_private_subnet" {
   count = length(var.gsp_cluster_vpc_id)
   filter {
    name   = "vpc-id"
    values = [local.env_name[count.index].vpcid]
  }
  
   filter {
    name   = "tag:Name"
    values = ["*-private-*",local.env_name[count.index].vpcname]
  }
 }

#Transit Gateway Attachments

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attach" {
  count = length(var.gsp_cluster_vpc_id)
  subnet_ids = data.aws_subnets.gsp_vpc_private_subnet[count.index].ids
  transit_gateway_id = var.transit_gateway_id
  vpc_id = local.env_name[count.index].vpcid
  dns_support = var.dns_support
  tags = merge(
    {
    #"Name" = "${local.env_name[count.index].vpcname}-tg-attachment"
    "Name" = "${var.gsp_cluster_vpc_name[count.index]}-tg-attachment"
    }
  )
  transit_gateway_default_route_table_association = var.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = var.transit_gateway_default_route_table_propagation
}

#transit gateway association
resource "aws_ec2_transit_gateway_route_table_association" "tgw_rtb_assoc" {
  count = length(var.gsp_cluster_vpc_id)
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_attach[count.index].id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

#transit gateway propagation
resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_rtb_prop" {
  count = length(var.gsp_cluster_vpc_id)
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_attach[count.index].id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

# #transit gateway route
# resource "aws_ec2_transit_gateway_route" "tgw_route" {
#   destination_cidr_block         = "0.0.0.0/0"
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_attach.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rtb.id
# }

# Private Route table entry for GSP  

data "aws_route_tables" "gsp_vpc_route_tables" {
  count = var.tgw_secondary ? 0 : length(var.gsp_cluster_vpc_id)
  vpc_id                     = element(var.gsp_cluster_vpc_id,count.index)
  filter {
    name   = "tag:Name"
    values = ["*-private-*","*-private"]
  }
}

locals {
  route_table_ids = flatten([for rt_ids in data.aws_route_tables.gsp_vpc_route_tables : rt_ids.ids])
}
resource "aws_route" "gsp_tgw_private_dest" {
  count = length(local.route_table_ids)
  route_table_id            = local.route_table_ids[count.index]
  destination_cidr_block    = var.middleware_vpc_cidr
  transit_gateway_id        = var.transit_gateway_id
  }

locals {
  private_routes = flatten(
    [for rtb_id in var.private_route_table_ids : [
      for idx, vpc in data.aws_vpc.gsp_vpc_id : {
          route_table_id = rtb_id
          destination_cidr_block = vpc.cidr_block
        }
      ]
    ]
  )
}
# Private Route table entry for middleware vpc
resource "aws_route" "middleware_vpc_tgw_private_dest" {
  count                     = length(local.private_routes)
  route_table_id            = local.private_routes[count.index].route_table_id
  destination_cidr_block    = local.private_routes[count.index].destination_cidr_block ##This should contain cluster vpc cidr range
  transit_gateway_id        = var.transit_gateway_id
  }

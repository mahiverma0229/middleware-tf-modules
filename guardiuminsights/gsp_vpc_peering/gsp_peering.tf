
# Setting up PVC peering with gsp cluster 

data "aws_vpc" "gsp_cluster_vpc" {
  count = var.gsp_cluster_vpc_enabled ? length(var.gsp_cluster_vpc_id) : 0
  id = element(var.gsp_cluster_vpc_id, count.index)
  filter {
    name   = "tag:Name"
    values = [coalesce(var.gsp_cluster_vpc_name[count.index], "*-vpc")]
  }
}

# VPC peering connection GI -> GSP
resource "aws_vpc_peering_connection" "gsp_cluster_vpc" {
  count = var.gsp_cluster_vpc_enabled ? length(var.gsp_cluster_vpc_id) : 0
  vpc_id  = var.middleware_vpc_id
  peer_vpc_id = data.aws_vpc.gsp_cluster_vpc[count.index].id
  auto_accept = true

  tags = {
    #Name  = "sgi_dspm-dev01-peering-connection"
    Name = "${var.gsp_cluster_vpc_name[count.index]}-peering-connection"
  }
}
locals {
  private_routes = flatten(
    [for rtb_id in var.private_route_table_ids : [
      for idx, vpc in data.aws_vpc.gsp_cluster_vpc : {
          route_table_id = rtb_id
          destination_cidr_block = vpc.cidr_block
          vpc_peering_connection_id = aws_vpc_peering_connection.gsp_cluster_vpc[idx].id
        }
      ]
    ]
  )
}
locals {
  public_routes = flatten(
    [for rtb_id in var.public_route_table_ids : [
      for idx, vpc in data.aws_vpc.gsp_cluster_vpc : {
          route_table_id = rtb_id
          destination_cidr_block = vpc.cidr_block
          vpc_peering_connection_id = aws_vpc_peering_connection.gsp_cluster_vpc[idx].id
        }
      ]
    ]
  )
}

# Routes for GI private route tables
resource "aws_route" "cluster_vpc_peering_private" {
  count                      =  var.gsp_cluster_vpc_enabled ? length(local.private_routes) : 0
  route_table_id             = local.private_routes[count.index].route_table_id
  destination_cidr_block     = local.private_routes[count.index].destination_cidr_block
  vpc_peering_connection_id  = local.private_routes[count.index].vpc_peering_connection_id
}

# Routes for GI public route tables
resource "aws_route" "cluster_vpc_peering_public" {
  count                      = var.gsp_cluster_vpc_enabled ? length(local.public_routes) : 0
  route_table_id             = local.public_routes[count.index].route_table_id
  destination_cidr_block     = local.public_routes[count.index].destination_cidr_block
  vpc_peering_connection_id  = local.public_routes[count.index].vpc_peering_connection_id
}

# fetch private route tables for GSP
data "aws_route_tables" "gsp_cluster_vpc_route_tables" {
  count  = var.gsp_cluster_vpc_enabled ? length(var.gsp_cluster_vpc_id) : 0
  vpc_id = element(var.gsp_cluster_vpc_id, count.index)
  filter {
    name   = "tag:Name"
    values = ["Private*", "*-private-*", "*-private"]
  }
}

# local variable to map each peering VPC to route table ids
locals {
  gsp_route_table_map = {
    for vpc_id, route_tables in data.aws_route_tables.gsp_cluster_vpc_route_tables :
    vpc_id => route_tables.ids
  }
}

locals {
  route_list = flatten([
    for vpc_id, route_table_ids in local.gsp_route_table_map : [
    for route_table_id in route_table_ids : 
    {
       vpc_id = vpc_id
       route_table_id = route_table_id
     }
    ]
  ]
  )
}

# local variable to map each VPC to its vpc peering connection id 
locals {

vpc_peering_connect_map = {
  for peer_vpc_id, id in aws_vpc_peering_connection.gsp_cluster_vpc : 
  peer_vpc_id => id
} 
}

# Routes for GSP private route tables
resource "aws_route" "gsp_cluster_vpc_peering_private_dest" {
  for_each = { for item in local.route_list : "${item.vpc_id}-${item.route_table_id}" => item }
  route_table_id = each.value.route_table_id
  destination_cidr_block    = var.middleware_vpc_cidr
  vpc_peering_connection_id = local.vpc_peering_connect_map[each.value.vpc_id].id
}

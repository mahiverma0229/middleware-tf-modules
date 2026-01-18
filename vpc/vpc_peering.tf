data "aws_vpc" "selected_cluster_vpc" {
  count = var.connect_cluster_vpc ? 1 : 0

  id = var.connect_cluster_vpc_peer_id

  filter {
    name   = "tag:Name"
    values = [coalesce(var.connect_cluster_vpc_peer_name, "*-vpc")]
  }
}

resource "aws_vpc_peering_connection" "cluster_vpc" {
  count = var.connect_cluster_vpc ? 1 : 0

  vpc_id      = aws_vpc.vpc.id
  peer_vpc_id = data.aws_vpc.selected_cluster_vpc.0.id
  auto_accept = true

  tags = {
    Name = "${var.cluster_id}-peering-connection"
  }
}

resource "aws_route" "cluster_vpc_peering_private" {
  count = var.connect_cluster_vpc ? var.vpc_num_private_subnets : 0

  route_table_id            = element(aws_route_table.private_route_table.*.id, count.index)
  destination_cidr_block    = data.aws_vpc.selected_cluster_vpc.0.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cluster_vpc.0.id
}

resource "aws_route" "cluster_vpc_peering_public" {
  count = var.connect_cluster_vpc ? var.vpc_num_public_subnets : 0

  route_table_id            = element(aws_route_table.public_route_table.*.id, count.index)
  destination_cidr_block    = data.aws_vpc.selected_cluster_vpc.0.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cluster_vpc.0.id
}

data "aws_route_tables" "selected_cluster_vpc_route_tables" {
  vpc_id = one(data.aws_vpc.selected_cluster_vpc[*].id)
  filter {
    name   = "tag:Name"
    values = ["Private*", "*-private-*"]
  }
}

resource "aws_route" "selected_cluster_vpc_peering_private_dest" {
  count = var.connect_cluster_vpc ? length(data.aws_route_tables.selected_cluster_vpc_route_tables.ids) : 0

  route_table_id            = element(data.aws_route_tables.selected_cluster_vpc_route_tables.ids, count.index)
  destination_cidr_block    = aws_vpc.vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cluster_vpc.0.id
}

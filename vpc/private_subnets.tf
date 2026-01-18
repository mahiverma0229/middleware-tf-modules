resource "aws_subnet" "private_subnet" {
  count = var.vpc_num_private_subnets

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  # offset to include public subnets.
  cidr_block              = var.old_subnets_toggle ? cidrsubnet(var.vpc_cidr, 2, count.index + 2) : cidrsubnet(var.vpc_cidr, var.vpc_newbits, count.index + var.vpc_num_public_subnets)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.vpc.id

  tags = merge (
    {
      Name = "${var.name_prefix}-${var.cluster_id}-${var.namespace_id}-private-subnet-${count.index}"
    }
  )
}

resource "aws_eip" "nat_eip" {
  count = "${var.vpc_num_private_subnets * var.vpc_num_public_subnets}" > 0 ? "${var.vpc_num_private_subnets}" : 0

  domain = "vpc"

  tags = merge (
    {
      Name = "${var.name_prefix}-${var.cluster_id}-nat-eip-${count.index}"
    }
  )
}

resource "aws_nat_gateway" "nat_gw" {
  depends_on = [
    aws_internet_gateway.igw
  ]
  count = "${var.vpc_num_private_subnets * var.vpc_num_public_subnets}" > 0 ? "${var.vpc_num_private_subnets}" : 0

  allocation_id = element(aws_eip.nat_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)

  tags = merge (
    {
      Name = "${var.name_prefix}-${var.cluster_id}-nat-gw-${count.index}"
    }
  )
}

resource "aws_route_table" "private_route_table" {
  count = var.vpc_num_private_subnets

  vpc_id = aws_vpc.vpc.id

  tags = merge (
    {
      Name = "${var.name_prefix}-${var.cluster_id}-private-route-table-${count.index}"
    }
  )
}

resource "aws_route_table_association" "private_route_table_assocation" {
  count = var.vpc_num_private_subnets

  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
}

resource "aws_route" "private_route" {
  count = "${var.vpc_num_private_subnets * var.vpc_num_public_subnets}" > 0 ? "${var.vpc_num_private_subnets}" : 0

  route_table_id         = element(aws_route_table.private_route_table.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat_gw.*.id, count.index)
}

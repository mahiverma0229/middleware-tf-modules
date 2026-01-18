resource "aws_internet_gateway" "igw" {
  count = "${var.vpc_num_public_subnets}" > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge (
    {
      Name = "${var.name_prefix}-${var.cluster_id}-${var.namespace_id}-igw"
    }
  )
}

resource "aws_subnet" "public_subnet" {
  count = var.vpc_num_public_subnets

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = var.old_subnets_toggle ? cidrsubnet(var.vpc_cidr, 3, count.index) : cidrsubnet(var.vpc_cidr, var.vpc_newbits, count.index)
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.vpc.id

  tags = merge (
    {
    Name = "${var.name_prefix}-${var.cluster_id}-${var.namespace_id}-public-subnet-${count.index}"
    }
  )
}

resource "aws_route_table" "public_route_table" {
  count  = var.vpc_num_public_subnets
  vpc_id = aws_vpc.vpc.id

  tags = merge (
    {
      Name = "${var.name_prefix}-${var.cluster_id}-${var.namespace_id}-public-route-table-${count.index}"
    }
  )
}

resource "aws_route_table_association" "public_route_table_association" {
  count = var.vpc_num_public_subnets

  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.public_route_table.*.id, count.index)
}

resource "aws_route" "public_route" {
  count = var.vpc_num_public_subnets

  route_table_id         = element(aws_route_table.public_route_table.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = one(aws_internet_gateway.igw[*].id)
}

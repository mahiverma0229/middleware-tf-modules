output "vpc" {
  value = aws_vpc.vpc.id
}

output "cidr_block" {
  value = aws_vpc.vpc.cidr_block
}

output "vpc_peering_id" {
  value = length(aws_vpc_peering_connection.cluster_vpc) > 0 ? aws_vpc_peering_connection.cluster_vpc.0.id : ""
}

output "vpc_peer_cidr" {
  value = one(data.aws_vpc.selected_cluster_vpc[*].cidr_block)
}

output "igw" {
  value = one(aws_internet_gateway.igw[*].id)
}

output "public_subnet" {
  value = aws_subnet.public_subnet.*.id
}

output "public_subnet_az" {
  value = aws_subnet.public_subnet.*.availability_zone
}

output "private_subnet" {
  value = aws_subnet.private_subnet.*.id
}

output "private_subnet_az" {
  value = aws_subnet.private_subnet.*.availability_zone
}

output "nat_eip" {
  value = aws_eip.nat_eip.*.public_ip
}

output "all_middleware_sg" {
  value = aws_security_group.all_middleware_sg.id
}

output "aws_availability_zones" {
  value = data.aws_availability_zones.available
}

output "private_route_table_ids" {
  value = aws_route_table.private_route_table[*].id
}

output "public_route_table_ids" {
  value = aws_route_table.public_route_table[*].id
}
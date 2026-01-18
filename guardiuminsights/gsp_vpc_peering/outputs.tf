/*
output "vpc" {
  value = aws_vpc.vpc.id
}

output "cidr_block" {
  value = aws_vpc.vpc.cidr_block
}
*/
output "vpc_peering_id" {
  value = aws_vpc_peering_connection.gsp_cluster_vpc.*.id
}

output "vpc_peer_cidr" {
  value = data.aws_vpc.gsp_cluster_vpc[*].cidr_block
}


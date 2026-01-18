locals {
  kafka_public_urls = aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_public_tls
  kafka_public_hosts = {
    value = [for s in split(",", local.kafka_public_urls) : split(":", s)[0] if s != ""]
  }
}

data "dns_a_record_set" "kafka_public_host_ip_addrs" {
  for_each = var.setup_phase != "final" ? toset([]) : toset(local.kafka_public_hosts.value)
  host     = each.value
}

output "kafka_public_ips" {
  value =  [for i in values(data.dns_a_record_set.kafka_public_host_ip_addrs) : join(" ,", i.addrs)]
}

output "kafka_admin_user" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.kafka_secrets.secret_string)["username"]
  sensitive = true
}

output "kafka_admin_password" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.kafka_secrets.secret_string)["password"]
  sensitive = true
}

output "bootstrap_brokers_sasl_iam" {
  value = aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_sasl_iam
}

output "bootstrap_brokers_public_sasl_iam" {
  value = aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_public_sasl_iam
}

output "bootstrap_brokers_sasl_scram" {
  value = aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_sasl_scram
}

output "bootstrap_brokers_public_sasl_scram" {
  value = aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_public_sasl_scram
}

output "bootstrap_brokers_public_tls" {
  value = aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_public_tls
}

output "bootstrap_brokers_private_tls" {
  value = aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_tls
}

output "msk_sg" {
  value = aws_security_group.msk_sg.id
}

output "kafka-01_cluster_arn"{
  value = aws_msk_cluster.aws_msk_cluster.arn
}

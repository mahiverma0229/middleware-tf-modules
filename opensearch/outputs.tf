output "endpoint" {
  value = aws_elasticsearch_domain.opensearch.endpoint
}

output "password" {
  value     = aws_elasticsearch_domain.opensearch.advanced_security_options[0].master_user_options.*.master_user_password
  sensitive = true
}

output "username" {
  value = aws_elasticsearch_domain.opensearch.advanced_security_options[0].master_user_options.*.master_user_name
}

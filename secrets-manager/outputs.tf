output "secrets_manager_kms_key_arn" {
    value = aws_secretsmanager_secret.middleware-secrets.arn  
}
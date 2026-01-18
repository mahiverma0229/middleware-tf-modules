locals {
  secret_output_filtered = {
    for k,v in var.all_middleware_secrets : k => v if v!= null && v!= []
  }
}

resource "aws_secretsmanager_secret" "middleware-secrets" {
  name                    = var.middleware_secrets_manager_name
  kms_key_id              = var.sm_encryption_at_rest_kms_key_arn
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "middleware-secrets-val" {
  secret_id = aws_secretsmanager_secret.middleware-secrets.id
  secret_string = jsonencode(local.secret_output_filtered)
}

data "aws_secretsmanager_secret_version" "middleware-secrets-version" {
  secret_id  = aws_secretsmanager_secret.middleware-secrets.id
  version_id = aws_secretsmanager_secret_version.middleware-secrets-val.version_id
}


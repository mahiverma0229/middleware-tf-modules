resource "random_password" "rss_password" {
  count            = var.rss_enabled ? 1 : 0
  length           = 16
  special          = true
  min_numeric      = 1
  override_special = "!$%&*()-_=+[]{}<>:?"
}

resource "random_string" "rss_secret_name_random_id" {
  length  = 5
  special = false
}

resource "aws_secretsmanager_secret" "rss_secret_admin" {
  count                   = var.rss_enabled ? 1 : 0
  name                    = "AmazonRedshift_-${var.cluster_id}-${var.namespace_id}-rss-admin-secret-${random_string.rss_secret_name_random_id.result}"
  kms_key_id              = var.encryption_at_rest_kms_key_arn
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "rss_secret_admin" {
  count     = var.rss_enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.rss_secret_admin[0].id
  secret_string = jsonencode({
    username : var.rss_user_name
    password : random_password.rss_password[0].result
  })
}

data "aws_secretsmanager_secret_version" "rss_secrets" {
  count      = var.rss_enabled ? 1 : 0
  secret_id  = aws_secretsmanager_secret.rss_secret_admin[0].id
  version_id = aws_secretsmanager_secret_version.rss_secret_admin[0].version_id
}

resource "random_password" "redshift_password" {
  length           = 16
  special          = true
  min_numeric      = 1
  override_special = "!$%&*()-_=+[]{}<>:?"
}

resource "random_string" "redshift_secret_name_random_id" {
  length  = 5
  special = false
}

resource "aws_secretsmanager_secret" "redshift_secret_admin" {
  name                    = "AmazonRedshift_-${var.cluster_id}-${var.namespace_id}-redshift-admin-secret-${random_string.redshift_secret_name_random_id.result}"
  kms_key_id              = var.encryption_at_rest_kms_key_arn
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "redshift_secret_admin" {
  secret_id = aws_secretsmanager_secret.redshift_secret_admin.id
  secret_string = jsonencode({
    username : var.redshift_user_name
    password : random_password.redshift_password.result
  })
}

data "aws_secretsmanager_secret_version" "redshift_secrets" {
  secret_id  = aws_secretsmanager_secret.redshift_secret_admin.id
  version_id = aws_secretsmanager_secret_version.redshift_secret_admin.version_id
}

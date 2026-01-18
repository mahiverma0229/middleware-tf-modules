resource "random_password" "kafka_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_string" "kafka_secret_name_random_id" {
  length  = 5
  special = false
}

resource "aws_secretsmanager_secret" "kafka_secret_admin" {
  name                    = "AmazonMSK_-${var.cluster_id}-${var.namespace_id}-kafka-admin-secret-${random_string.kafka_secret_name_random_id.result}"
  kms_key_id              = var.encryption_at_rest_kms_key_arn
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "kafka_secret_admin" {
  secret_id = aws_secretsmanager_secret.kafka_secret_admin.id
  secret_string = jsonencode({
    username : "kafka-admin"
    password : random_password.kafka_password.result
  })
}

data "aws_secretsmanager_secret_version" "kafka_secrets" {
  secret_id  = aws_secretsmanager_secret.kafka_secret_admin.id
  version_id = aws_secretsmanager_secret_version.kafka_secret_admin.version_id
}

# DSPM MSK user
resource "aws_secretsmanager_secret" "kafka-secret-gsp" {
  count                   = var.gsp_peering_enabled ? 1 : 0
  kms_key_id              = var.msk_kms_key_arn
  name                    = "AmazonMSK_-${var.gsp_cluster_id}-${var.identifier_id}-kafka-Secret-GSP"
  policy                  = var.policy
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "kafka-secret-gsp" {
  count     = var.gsp_peering_enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.kafka-secret-gsp[0].id
  secret_string = jsonencode({
    username : "kafka-gsp"
    password : random_password.kafka_password.result
  })
}

data "aws_secretsmanager_secret_version" "kafka_secrets-gsp" {
  count      = var.gsp_peering_enabled ? 1 : 0
  secret_id  = aws_secretsmanager_secret.kafka-secret-gsp[0].id
  version_id = aws_secretsmanager_secret_version.kafka-secret-gsp[0].version_id
}

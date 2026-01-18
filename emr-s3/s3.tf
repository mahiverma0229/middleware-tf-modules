locals {
  # Extract environment name from cluster_id
  # Supports multiple patterns:
  # - "sgi-dev03" -> "dev03"
  # - "sgi-preprod01" -> "preprod01"
  # - "sgi-eu-prod01" -> "eu-prod01" (multi-region)
  
  # Try to match region-env pattern first (e.g., eu-prod01, ap-prod01)
  # Then fall back to simple env pattern (e.g., dev03, preprod01)
  environment_name = can(regex("-([a-z]+-[a-z]+[0-9]+)$", var.cluster_id)) ? regex("-([a-z]+-[a-z]+[0-9]+)$", var.cluster_id)[0] : (
    can(regex("-([a-z]+[0-9]+)$", var.cluster_id)) ? regex("-([a-z]+[0-9]+)$", var.cluster_id)[0] : var.cluster_id
  )
  
  # Determine if we should create a new bucket or use an existing one
  create_bucket = var.emr_bucket_name == null
  
  # Use provided bucket name or auto-generate: emr-datalake-{env}-bucket
  emr_datalake_bucket_name = var.emr_bucket_name != null ? var.emr_bucket_name : "emr-datalake-${local.environment_name}-bucket"
}

# S3 bucket for EMR bootstrap scripts and data
resource "aws_s3_bucket" "emr_datalake_bucket" {
  bucket        = local.emr_datalake_bucket_name
  force_destroy = false  # Prevent accidental deletion - bucket must be empty before deletion
}

resource "aws_s3_bucket_versioning" "emr_bootstrap_versioning" {
  bucket = aws_s3_bucket.emr_datalake_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "emr_bootstrap_encryption" {
  bucket = aws_s3_bucket.emr_datalake_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      # Use KMS encryption if enabled and key is provided, otherwise use AES256
      kms_master_key_id = var.emr_encryption_enabled && var.emr_kms_key_arn != "" ? var.emr_kms_key_arn : null
      sse_algorithm     = var.emr_encryption_enabled && var.emr_kms_key_arn != "" ? "aws:kms" : "AES256"
    }
    bucket_key_enabled = var.emr_encryption_enabled && var.emr_kms_key_arn != "" ? true : false
  }
}

# Upload bootstrap scripts to S3 (bootstrap/ folder)
resource "aws_s3_object" "bootstrap_scripts" {
  for_each = fileset("${path.module}/scripts", "*.sh")
  
  bucket = aws_s3_bucket.emr_datalake_bucket.id
  key    = "bootstrap/${each.value}"
  source = "${path.module}/scripts/${each.value}"
  etag   = filemd5("${path.module}/scripts/${each.value}")
}

# Create iceberg warehouse folder (iceberg-<env>-warehouse/)
resource "aws_s3_object" "iceberg_warehouse_folder" {
  bucket = aws_s3_bucket.emr_datalake_bucket.id
  key    = "iceberg-${local.environment_name}-warehouse/"
}

# Create logs folder (<env>-logs/)
resource "aws_s3_object" "logs_folder" {
  bucket = aws_s3_bucket.emr_datalake_bucket.id
  key    = "${local.environment_name}-logs/"
}
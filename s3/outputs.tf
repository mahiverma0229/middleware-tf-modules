output "bucket" {
  value = aws_s3_bucket.s3_bucket.bucket
}

output "bucket_domain_name" {
  value = aws_s3_bucket.s3_bucket.bucket_domain_name
}

output "bucket_arn" {
  value = aws_s3_bucket.s3_bucket.arn
}

output "region" {
  value = aws_s3_bucket.s3_bucket.region
}

output "iam_access_key_id" {
  value     = var.s3_bucket_user_name == "" ? aws_iam_access_key.s3_user_keys[0].id : "using the key for user ${var.s3_bucket_user_name}"
  sensitive = true
}

output "iam_access_key_secret" {
  value     = var.s3_bucket_user_name == "" ? aws_iam_access_key.s3_user_keys[0].secret : "using secret for user ${var.s3_bucket_user_name}"
  sensitive = true
}
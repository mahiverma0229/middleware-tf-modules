
resource "aws_iam_user" "s3_user" {
  count = var.s3_bucket_user_name == "" ? 1 : 0
  name  = var.s3_bucket_name == "" ? "srv_${var.cluster_id}-${var.namespace_id}-s3-bucket" : "srv_${var.s3_bucket_name}"
}

resource "aws_iam_access_key" "s3_user_keys" {
  count = var.s3_bucket_user_name == "" ? 1 : 0
  user  = var.s3_bucket_user_name == "" ? aws_iam_user.s3_user[0].name : var.s3_bucket_user_name
}

# This policy is only needed until the teams converge and used a single bucket.
resource "aws_iam_policy" "s3_other_policy" {
  count       = var.s3_bucket_user_name == "" ? 1 : 0
  name        = "srv_${var.cluster_id}-${var.namespace_id}-s3-bucket-policy"
  path        = "/"
  description = "Policy for access ${var.s3_bucket_user_name == "" ? aws_iam_user.s3_user[0].name : var.s3_bucket_user_name} to access buckets related to cluster ${var.cluster_id} for namespace: ${var.namespace_id}"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject"
          ],
          "Resource" : [
            "arn:aws:s3:::aitk-exports*",
            "arn:aws:s3:::data-explorer-exports*",
            "arn:aws:s3:::*uds-search*",
            "arn:aws:s3:::health-check-*",
            "arn:aws:s3:::soar-jvmdumps-*",
            "arn:aws:s3:::tis-xir*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:PutLifecycleConfiguration",
            "s3:CreateBucket",
            "s3:ListBucket",
            "s3:PutBucketCORS",
            "s3:DeleteBucket"
          ],
          "Resource" : [
            "arn:aws:s3:::aitk-exports*",
            "arn:aws:s3:::data-explorer-exports*",
            "arn:aws:s3:::*uds-search*",
            "arn:aws:s3:::health-check-*",
            "arn:aws:s3:::soar-jvmdumps-*",
            "arn:aws:s3:::tis-xir*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kms:Decrypt",
            "kms:GenerateDataKey",
            "kms:GenerateDataKeyPair"
          ],
          "Resource" : [
            "${aws_kms_key.s3_kms_key.arn}",
          ]
        }
      ]
  })
}

resource "aws_iam_user_policy_attachment" "s3_user_policy_attach" {
  count      = var.s3_bucket_user_name == "" ? 1 : 0
  user       = var.s3_bucket_user_name == "" ? aws_iam_user.s3_user[0].name : var.s3_bucket_user_name
  policy_arn = one(aws_iam_policy.s3_other_policy[*].arn)
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.s3_bucket_name == "" ? "${var.cluster_id}-${var.namespace_id}-s3-bucket" : var.s3_bucket_name
  # TODO - review.
  force_destroy = true

  tags = merge(
    {
      Name = var.s3_bucket_name == "" ? "${var.cluster_id}-${var.namespace_id}-s3-bucket" : var.s3_bucket_name
    },
  )

}
// aws s3 lifecycle parameter passed only for CP4S
resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
  count = var.s3_lifecycle_archival_rule_status == "Enabled" || var.s3_lifecycle_expiration_status == "Enabled" ?  1 : 0

  bucket = aws_s3_bucket.s3_bucket.bucket

  dynamic "rule" {
    for_each = var.s3_lifecycle_expiration_status == "Enabled" ? [1] : []
    content {
      id     = "expiration-rule"
      status = var.s3_lifecycle_expiration_status
      expiration {
        days = var.s3_lifecycle_expiration_days
      }
    }
  }

  dynamic "rule" {
    for_each = var.s3_lifecycle_archival_rule_status == "Enabled" ? [1] : []
    content {
      id     = "archival-rule"
      status = var.s3_lifecycle_archival_rule_status
      dynamic "transition" {
        for_each = var.s3_lifecycle_archival_rule_status == "Enabled" ? [1] : []
        content {
          storage_class = var.s3_lifecycle_archival_storage_class
          days = var.s3_lifecycle_transition_days
        }
      }
      dynamic "filter" {
        for_each = var.s3_lifecycle_archival_storage_prefix != "" ? [1] : []
        content {
          prefix = var.s3_lifecycle_archival_storage_prefix
        }
      }
    }
  }
}

resource "aws_kms_key" "s3_kms_key" {
  description = "Used to encrypt ${aws_s3_bucket.s3_bucket.id}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_server_side_encrypt" {
  bucket = aws_s3_bucket.s3_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.s3_bucket.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.s3_bucket_user_arn == "" ? aws_iam_user.s3_user[0].arn : var.s3_bucket_user_arn}"
      },
      "Action": [ "s3:*" ],
      "Resource": [
        "${aws_s3_bucket.s3_bucket.arn}",
        "${aws_s3_bucket.s3_bucket.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = var.s3_bucket_versioning
  }
}

#TODO -- look at aws_s3_bucket_lifecycle_configuration to clean up incomplete, or old versions, etc.

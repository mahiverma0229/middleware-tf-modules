moved {
  from = aws_iam_user.s3_user
  to   = aws_iam_user.s3_user[0]
}

moved {
  from = aws_iam_access_key.s3_user_keys
  to   = aws_iam_access_key.s3_user_keys[0]
}

moved {
  from = aws_iam_user_policy_attachment.s3_user_policy_attach
  to   = aws_iam_user_policy_attachment.s3_user_policy_attach[0]
}

moved {
  from = aws_iam_policy.s3_other_policy
  to   = aws_iam_policy.s3_other_policy[0]
}

resource "aws_iam_role" "iam_dev_role_snowflake" {
  name = "iam_for_dev_layer_snowflake"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"  
        },
      }
    ]
  })
}


data "aws_iam_policy_document" "pipeline_dev_policy_snowflake" {
  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy",
      "logs:DeleteLogGroup",
      "logs:DeleteLogStream"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "kms:*",
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }
}
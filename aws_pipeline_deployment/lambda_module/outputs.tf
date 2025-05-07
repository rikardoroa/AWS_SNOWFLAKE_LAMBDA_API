output "iam_for_dev_name" {
  value = aws_iam_role.iam_dev_role.name
}

output "policy_for_dev" {
  value = data.aws_iam_policy_document.pipeline_dev_policy_snowflake.json
}

output "iam_for_dev_arn" {
  value = aws_iam_role.iam_dev_role.arn
}
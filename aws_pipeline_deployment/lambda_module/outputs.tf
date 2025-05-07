output "iam_for_dev_name" {
  value = aws_iam_role.iam_dev_role_snowflake.name
}

output "policy_for_dev" {
  value = data.aws_iam_policy_document.pipeline_dev_policy_snowflake.json
}

output "iam_for_dev_arn" {
  value = aws_iam_role.iam_dev_role_snowflake.arn
}


output "lambda_function" {
  value = aws_lambda_function.lambda_function
}


output "invoke_arn" {
  value = aws_lambda_function.lambda_function.arn
}
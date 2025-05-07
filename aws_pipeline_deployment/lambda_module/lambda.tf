#lambda role and policy
resource "aws_iam_role_policy" "lambda_s3_monitoring" {
  name   = "lambda_logging_with_layer"
  role   = aws_iam_role.iam_dev_role_snowflake.name
  policy = data.aws_iam_policy_document.pipeline_dev_policy_snowflake.json
}

# wait 10 seconds until image aprovisioning
resource "null_resource" "wait_for_image" {
  provisioner "local-exec" {
    # command = "powershell -Command Start-Sleep -Seconds 10"  # Esperar 10 segundos
     command = "sleep 10"  # Esperar 10 segundos
  }

  depends_on = [
    null_resource.push_image
  ]
}


# after image aprovisioning, the lambda creation starts using ECR repository
resource "aws_lambda_function" "lambda_function" {
  function_name = "api-incd-docker-lambda"
  image_uri     = "${aws_ecr_repository.lambda_repository.repository_url}:latest"
  package_type  = "Image"
  role          = aws_iam_role.iam_dev_role_snowflake.arn
  timeout =     var.lambda_timeout
  memory_size   = 500
  depends_on = [
    null_resource.wait_for_image
  ]
}


# s3 invokation
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket_creation.arn
}

# lambda trigger
resource "aws_s3_bucket_notification" "notify_lambda" {
  bucket =  aws_s3_bucket.bucket_creation.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]  # react to any new object
    filter_suffix       = ".csv"                  # optional ,only .csv files
  }

  depends_on = [aws_lambda_permission.allow_s3]   # ensure permission exists first
}
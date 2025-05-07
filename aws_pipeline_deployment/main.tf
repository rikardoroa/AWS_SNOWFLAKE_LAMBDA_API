module "aws_lambda_utils" {
  source       = "./lambda_module"
}


module "api_gateway_utils" {
  source        = "./api_gateway_module"
  invoke_arn    = module.aws_lambda_utils.lambda_function.invoke_arn
  function_name = module.aws_lambda_utils.lambda_function.function_name
}
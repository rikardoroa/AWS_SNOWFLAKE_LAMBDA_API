# creating api gateway object
resource "aws_api_gateway_rest_api" "snowflakehook" {
  name        = "snowflakehook"
  description = "Snowflake API connection"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# creating api gateway path
resource "aws_api_gateway_resource" "snowflakewebhookpath" { 
  parent_id   = aws_api_gateway_rest_api.snowflakehook.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.snowflakehook.id
  path_part   = "SnowflakeGetData"
}

# creating api gateway method
resource "aws_api_gateway_method" "snowflakewebhookmethod" { 
  authorization = "NONE" # Cambiado a NONE para permitir acceso sin autenticación
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.snowflakewebhookpath.id
  rest_api_id   = aws_api_gateway_rest_api.snowflakehook.id
}

# creating api gateway response
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.snowflakehook.id
  resource_id = aws_api_gateway_resource.snowflakewebhookpath.id
  http_method = aws_api_gateway_method.snowflakewebhookmethod.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

# creating api gateway lambda integration
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.snowflakehook.id
  resource_id             = aws_api_gateway_resource.snowflakewebhookpath.id
  http_method             = aws_api_gateway_method.snowflakewebhookmethod.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.invoke_arn
}



# permission to invoke lambda from api gateway
resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.snowflakehook.execution_arn}/dev/*"
}

# Creating API Gateway deployment
resource "aws_api_gateway_deployment" "snowflake_deployment" { 
  rest_api_id = aws_api_gateway_rest_api.snowflakehook.id

  # Dependemos del método para asegurarnos de que todo esté listo antes de desplegar
  depends_on = [
    aws_api_gateway_method.snowflakewebhookmethod,
    aws_api_gateway_integration.integration,
    aws_api_gateway_method_response.response_200,
  ]
}

# Creating API Gateway stage
resource "aws_api_gateway_stage" "snowflake_stage" {
  deployment_id = aws_api_gateway_deployment.snowflake_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.snowflakehook.id
  stage_name    = "dev"
}

# Method settings to customize caching and throttling
resource "aws_api_gateway_method_settings" "snowflake_method_settings" {
  rest_api_id  = aws_api_gateway_rest_api.snowflakehook.id
  stage_name   = aws_api_gateway_stage.snowflake_stage.stage_name
  method_path  = "*/*"
  settings {
    cache_data_encrypted  = false
    cache_ttl_in_seconds  = 0
    throttling_burst_limit = 500
    throttling_rate_limit  = 1000
  }
}
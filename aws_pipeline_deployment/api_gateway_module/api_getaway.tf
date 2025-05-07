
# REST API   
resource "aws_api_gateway_rest_api" "snowflakehook" {
  name        = "snowflakehook"
  description = "Snowflake API connection"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


# creating api gateway path
resource "aws_api_gateway_resource" "snowflakewebhookpath" {
  rest_api_id = aws_api_gateway_rest_api.snowflakehook.id
  parent_id   = aws_api_gateway_rest_api.snowflakehook.root_resource_id
  path_part   = "SnowflakeGetData"
}

# creating api gateway method for post
resource "aws_api_gateway_method" "snowflakewebhookmethod_post" {
  rest_api_id   = aws_api_gateway_rest_api.snowflakehook.id
  resource_id   = aws_api_gateway_resource.snowflakewebhookpath.id
  http_method   = "POST"
  authorization = "NONE"
}

# post response
resource "aws_api_gateway_method_response" "response_200_post" {
  rest_api_id = aws_api_gateway_rest_api.snowflakehook.id
  resource_id = aws_api_gateway_resource.snowflakewebhookpath.id
  http_method = aws_api_gateway_method.snowflakewebhookmethod_post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# post integration
resource "aws_api_gateway_integration" "integration_post" {
  rest_api_id             = aws_api_gateway_rest_api.snowflakehook.id
  resource_id             = aws_api_gateway_resource.snowflakewebhookpath.id
  http_method             = aws_api_gateway_method.snowflakewebhookmethod_post.http_method
  type                    = "AWS_PROXY"

  # Con AWS_PROXY el método de integración debe ser POST, aunque el externo sea POST o GET
  integration_http_method = "POST"
  uri                     = var.invoke_arn
}


# creating api gateway method for get
resource "aws_api_gateway_method" "snowflakewebhookmethod_get" {
  rest_api_id   = aws_api_gateway_rest_api.snowflakehook.id
  resource_id   = aws_api_gateway_resource.snowflakewebhookpath.id
  http_method   = "GET"
  authorization = "NONE"
}

# get response
resource "aws_api_gateway_method_response" "response_200_get" {
  rest_api_id = aws_api_gateway_rest_api.snowflakehook.id
  resource_id = aws_api_gateway_resource.snowflakewebhookpath.id
  http_method = aws_api_gateway_method.snowflakewebhookmethod_get.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# get integration
resource "aws_api_gateway_integration" "integration_get" {
  rest_api_id             = aws_api_gateway_rest_api.snowflakehook.id
  resource_id             = aws_api_gateway_resource.snowflakewebhookpath.id
  http_method             = aws_api_gateway_method.snowflakewebhookmethod_get.http_method
  type                    = "AWS_PROXY"


  integration_http_method = "POST"
  uri                     = var.invoke_arn
}

# lambda invokation
resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "apigateway.amazonaws.com"

  # Permite cualquier método dentro del stage dev
  source_arn = "${aws_api_gateway_rest_api.snowflakehook.execution_arn}/dev/*"
}

# deployment for post and get
resource "aws_api_gateway_deployment" "snowflake_deployment" {
  rest_api_id = aws_api_gateway_rest_api.snowflakehook.id

  depends_on = [
    # POST
    aws_api_gateway_method.snowflakewebhookmethod_post,
    aws_api_gateway_integration.integration_post,
    aws_api_gateway_method_response.response_200_post,

    # GET
    aws_api_gateway_method.snowflakewebhookmethod_get,
    aws_api_gateway_integration.integration_get,
    aws_api_gateway_method_response.response_200_get,
  ]
}

resource "aws_api_gateway_stage" "snowflake_stage" {
  rest_api_id   = aws_api_gateway_rest_api.snowflakehook.id
  deployment_id = aws_api_gateway_deployment.snowflake_deployment.id
  stage_name    = "dev"
}


#caching and  throttling

resource "aws_api_gateway_method_settings" "snowflake_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.snowflakehook.id
  stage_name  = aws_api_gateway_stage.snowflake_stage.stage_name
  method_path = "*/*"   # Cubre todos los verbos y rutas

  settings {
    cache_data_encrypted   = false
    cache_ttl_in_seconds   = 0
    throttling_burst_limit = 500
    throttling_rate_limit  = 1000
  }
}

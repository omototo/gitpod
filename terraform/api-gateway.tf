#API Gateway
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "MyDemoAPI"
  description = "My Demo API for lambda"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "test"
}
resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_image_processor.invoke_arn
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_image_processor.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.integration
  ]
  rest_api_id = aws_api_gateway_rest_api.my_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.my_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_api_gateway_stage" "example" {
  deployment_id         = aws_api_gateway_deployment.deployment.id
  rest_api_id           = aws_api_gateway_rest_api.my_api.id
  stage_name            = "flip-image"
  cache_cluster_enabled = true
  cache_cluster_size    = "0.5" # Example size, adjust as necessary
  description           = "My demo API deployment"
  xray_tracing_enabled  = true


  # Ensure updates to the integration causes a new deployment.
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_api_gateway_method_settings" "settings" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = aws_api_gateway_stage.example.stage_name
  method_path = "${aws_api_gateway_resource.resource.path_part}/${aws_api_gateway_method.method.http_method}"

  settings {
    caching_enabled                            = true
    cache_ttl_in_seconds                       = 300 # Example TTL, adjust as necessary
    cache_data_encrypted                       = false
    require_authorization_for_cache_control    = false
    unauthorized_cache_control_header_strategy = "SUCCEED_WITH_RESPONSE_HEADER"
    logging_level                              = "INFO"
  }
}



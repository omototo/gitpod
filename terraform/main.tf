provider "aws" {
  region = var.aws_region
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/my-api"
  retention_in_days = 7 # Change as per your needs
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/demo-container"
  retention_in_days = 14 # you can modify this based on your retention needs
}








provider "aws" {

  region = "us-east-2"
  default_tags {
    tags = {
      Name        = local.name
      Environment = local.environment
    }
  }
}

data "aws_caller_identity" "current" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.37.0"
    }
  }
}


resource "aws_accessanalyzer_analyzer" "handler" {
  analyzer_name = local.name
  type          = "ACCOUNT"
}


resource "aws_iam_role" "lambda" {
  name = local.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "handler" {
  name       = local.name
  roles      = [aws_iam_role.lambda.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_api_gateway_rest_api" "default" {
  name        = local.name
  description = "API Gateway to expose Lambda function"
}

resource "aws_api_gateway_deployment" "default" {
  # depends_on = [aws_api_gateway_integration.handler_any]
  # depends_on = [aws_api_gateway_integration.lambda]

  rest_api_id = aws_api_gateway_rest_api.default.id
  stage_name  = local.environment
}

###
# Root
##
resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.default.id
  resource_id   = aws_api_gateway_rest_api.default.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  resource_id = aws_api_gateway_rest_api.default.root_resource_id
  http_method = aws_api_gateway_method.root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.default.invoke_arn
}

resource "aws_api_gateway_method_response" "root" {
  rest_api_id   = aws_api_gateway_rest_api.default.id
  resource_id   = aws_api_gateway_rest_api.default.root_resource_id
  http_method   = aws_api_gateway_method.root.http_method
  status_code   = "200"
}

resource "aws_api_gateway_integration_response" "root" {
  depends_on = [aws_api_gateway_integration.root]

  rest_api_id = aws_api_gateway_rest_api.default.id
  resource_id = aws_api_gateway_rest_api.default.root_resource_id
  http_method = aws_api_gateway_integration.root.http_method
  status_code = aws_api_gateway_method_response.root.status_code
}


###
# Proxy
##

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  parent_id   = aws_api_gateway_rest_api.default.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.default.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST" # AWS Lambda uses POST for invocations
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.default.invoke_arn
}

resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.default.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = aws_api_gateway_method.proxy.http_method
  status_code   = "200"
}

resource "aws_api_gateway_integration_response" "proxy" {
  depends_on = [aws_api_gateway_integration.proxy]

  rest_api_id = aws_api_gateway_rest_api.default.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_integration.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code
}
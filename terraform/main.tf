provider "aws" {
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


resource "aws_api_gateway_rest_api" "api" {
  name        = local.name
  description = "API Gateway to expose Lambda function"
}

resource "aws_api_gateway_deployment" "api" {
  depends_on = [aws_api_gateway_integration.handler_any]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = local.environment
}
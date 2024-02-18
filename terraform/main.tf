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

data "archive_file" "handler" {  
  type = "zip"  
  source_file = "${path.module}/../src/handler.py" 
  output_path = "${local.name}.zip"
}

resource "aws_accessanalyzer_analyzer" "handler" {
  analyzer_name = local.name
  type          = "ACCOUNT" # or ORGANIZATION
}

resource "aws_lambda_function" "handler" {
  function_name = local.name

  # The S3 bucket and object or local file path to the zipped code
  filename         = data.archive_file.handler.output_path
  source_code_hash = filebase64sha256(data.archive_file.handler.output_path)

  handler = "handler.handler" # Assuming your entry point is handler.py and the main function is handler
  runtime = "python3.9"

  role = aws_iam_role.handler.arn

  tracing_config {
    mode = "Active"
  }

  # Optional configurations
  memory_size = 128
  timeout     = 30
}

resource "aws_iam_role" "handler" {
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
  roles      = [aws_iam_role.handler.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "handler" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handler.arn
  principal     = "apigateway.amazonaws.com"

  # The source ARN specifies the API Gateway REST API and the wildcard indicates all stages and methods
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_api_gateway_rest_api" "api" {
  name        = local.name
  description = "API Gateway to expose Lambda function"
}

resource "aws_api_gateway_method" "api" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  # resource_id   = aws_api_gateway_resource.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.api.http_method

  integration_http_method = "POST" # AWS Lambda uses POST for invocations
  type                    = "AWS"
  uri                     = aws_lambda_function.handler.invoke_arn
}

resource "aws_api_gateway_deployment" "api" {
  depends_on = [aws_api_gateway_integration.api]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = local.environment
}

resource "aws_api_gateway_method_response" "default_200" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = aws_api_gateway_method.api.http_method
  status_code   = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "default_200" {
  depends_on = [aws_api_gateway_integration.api]

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_integration.api.http_method
  status_code = aws_api_gateway_method_response.default_200.status_code

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = false
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  selection_pattern = ""
}

resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id  # Adjust as needed
  http_method   = "OPTIONS"
  authorization = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "options_mock" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id  # Adjust as needed
  http_method = aws_api_gateway_method.options.http_method

  type                    = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id  # Adjust as needed
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}


resource "aws_api_gateway_integration_response" "options_mock_200" {
  depends_on = [aws_api_gateway_integration.options_mock]

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id  # Adjust as needed
  http_method = aws_api_gateway_integration.options_mock.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  # content_handling = "PASSTHROUGH"
}

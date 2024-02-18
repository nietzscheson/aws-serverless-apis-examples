resource "aws_api_gateway_resource" "handler" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "handler"
}

resource "aws_api_gateway_method" "handler_any" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.handler.id
  # resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "handler_any" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.handler.id
  http_method = aws_api_gateway_method.handler_any.http_method

  integration_http_method = "POST" # AWS Lambda uses POST for invocations
  type                    = "AWS"
  uri                     = aws_lambda_function.handler.invoke_arn
}



resource "aws_api_gateway_method_response" "handler_any" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.handler.id
  http_method   = aws_api_gateway_method.handler_any.http_method
  status_code   = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "handler_any" {
  depends_on = [aws_api_gateway_integration.handler_any]

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.handler.id
  http_method = aws_api_gateway_integration.handler_any.http_method
  status_code = aws_api_gateway_method_response.handler_any.status_code

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = false
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  selection_pattern = ""
}

resource "aws_api_gateway_method" "handler_options" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.handler.id  # Adjust as needed
  http_method   = "OPTIONS"
  authorization = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "handler_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.handler.id
  http_method = aws_api_gateway_method.handler_options.http_method

  type                    = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "handler_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.handler.id  # Adjust as needed
  http_method = aws_api_gateway_method.handler_options.http_method
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


resource "aws_api_gateway_integration_response" "handler_options" {
  depends_on = [aws_api_gateway_integration.handler_options]

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.handler.id  # Adjust as needed
  http_method = aws_api_gateway_integration.handler_options.http_method
  status_code = aws_api_gateway_method_response.handler_options.status_code

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
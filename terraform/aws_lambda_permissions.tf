resource "aws_lambda_permission" "handler" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handler.arn
  principal     = "apigateway.amazonaws.com"

  # The source ARN specifies the API Gateway REST API and the wildcard indicates all stages and methods
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
resource "aws_lambda_permission" "default" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.default.arn
  principal     = "apigateway.amazonaws.com"

  # The source ARN specifies the API Gateway REST API and the wildcard indicates all stages and methods
  source_arn = "${aws_api_gateway_rest_api.default.execution_arn}/*/*"
}
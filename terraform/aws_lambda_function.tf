# resource "aws_lambda_function" "handler" {
#   function_name = "${local.name}-handler"
# 
#   filename         = data.archive_file.handler.output_path
#   source_code_hash = filebase64sha256(data.archive_file.handler.output_path)
# 
#   handler = "handler.handler"
#   runtime = "python3.9"
# 
#   role = aws_iam_role.lambda.arn
# 
#   tracing_config {
#     mode = "Active"
#   }
# 
#   memory_size = 128
#   timeout     = 30
# }

resource "aws_lambda_function" "default" {
  function_name = "${local.name}"
  image_uri     = "${aws_ecr_repository.default.repository_url}:latest"
  depends_on    = [aws_ecr_repository.default]
  role          = aws_iam_role.lambda.arn
  package_type  = "Image"
}
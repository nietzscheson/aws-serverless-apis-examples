output "ecr_default_repository_url" {
  value = aws_ecr_repository.default.repository_url
}

output "base_url" {
  value = aws_api_gateway_deployment.default.invoke_url
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "project_name" {
  value = local.name
}

output "api_gateway_id" {
  value = aws_api_gateway_rest_api.default.id
}

output "environment" {
  value = local.environment
}
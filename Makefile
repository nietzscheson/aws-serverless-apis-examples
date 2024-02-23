TAG := $(shell date +%Y%m%d_%H%M%S)

.PHONY:
init: down volume pull build up
terraform.init:
	@if [ -d "./terraform/.terraform" ]; then \
		echo "Terraform is initialized."; \
	else \
		echo "Terraform is not initialized."; \
		terraform -chdir=terraform init; \
	fi
terraform.apply:
	terraform -chdir=terraform apply -auto-approve
terraform.output:
	terraform -chdir=terraform output
terraform.output.environment:
	@export $(shell terraform -chdir=terraform output -json | jq -r 'to_entries|map("\(.key | ascii_upcase)=\(.value.value)")|.[]' | xargs)
terraform.fmt:
	terraform -chdir=terraform fmt -check
terraform.diff:
	terraform -chdir=terraform fmt -diff
terraform.validate:
	terraform -chdir=terraform validate
api.docker.build:
	docker buildx build -t $(PROJECT_NAME) ./src
api.docker.tag: api.docker.build
	docker tag $(PROJECT_NAME):latest $(ECR_DEFAULT_REPOSITORY_URL):latest
api.docker.push: api.docker.tag
	docker push $(ECR_DEFAULT_REPOSITORY_URL):latest
aws.lambda.publish:
	aws lambda publish-version --function-name $(PROJECT_NAME)
aws.lambda.update:
	aws lambda update-function-code --function-name $(PROJECT_NAME) --image-uri $(ECR_DEFAULT_REPOSITORY_URL):latest --architecture x86_64
aws.apigw.deploy:
	aws apigateway create-deployment --rest-api-id $(API_GATEWAY_ID) --stage-name $(ENVIRONMENT)
aws.cognito.auth:
	aws cognito-idp initiate-auth --client-id $(COGNITO_USER_POOL_CLIENT_ID) --auth-flow USER_PASSWORD_AUTH --auth-parameters USERNAME=$(ADMIN_DEFAULT_USER),PASSWORD=$(DEFAULT_USER_PASSWORD) --query 'AuthenticationResult.IdToken' --output text
http.rest:
	@TOKEN=$$(make --silent aws.cognito.auth) && \
	http POST $(BASE_URL)/rest Authorization:$$TOKEN
http.graphql:
	@TOKEN=$$(make --silent aws.cognito.auth) && \
	http POST "$(BASE_URL)/graphql" Authorization:$$TOKEN <<< '{"query": "{ hello }"}'
deploy: terraform.init terraform.apply api.docker.push aws.lambda.update aws.apigw.deploy
chrome.attach.debug: up
	google-chrome --remote-debugging-port=9222 --user-data-dir=remote-debug-profile
output "server_api_endpoint" {
  value       = module.yopass.server_apigw_url
  description = "The API endpoint URL of the Yopass server"
}

output "test_user_credentials" {
  description = "The credentials of the test user"
  value = {
    username = aws_cognito_user.test_user.username
    password = nonsensitive(random_password.test_user_password.result)
  }
}

output "website_endpoint" {
  value       = "https://${local.domain_name}"
  description = "Address of the website_endpoint"
}

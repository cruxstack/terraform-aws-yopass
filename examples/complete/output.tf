output "website_endpoint" {
  value       = "https://${local.domain_name}"
  description = "Address of the website_endpoint"
}

output "server_api_endpoint" {
  value       = module.yopass.server_apigw_url
  description = "The API endpoint URL of the Yopass server"
}

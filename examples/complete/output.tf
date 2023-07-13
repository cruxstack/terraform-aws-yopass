output "server_api_endpoint" {
  value       = module.yopass.server_apigw_url
  description = "The API endpoint URL of the Yopass server"
}

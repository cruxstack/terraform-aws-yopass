output "yopass_server_server_endpoint" {
  value       = module.yopass.lambda_fn_execution_url
  description = "The URL of the Yopass server"
}

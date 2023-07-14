output "server_apigw_id" {
  value       = module.yopass_label.enabled ? aws_api_gateway_rest_api.this[0].id : ""
  description = "The ID of the Yopass server API Gateway."
}

output "server_apigw_url" {
  value       = local.yopass_server_apigw_url
  description = "The URL of the Yopass server API Gateway."
}

output "website_cloudfront_domain_name" {
  value       = module.yopass_label.enabled ? module.yopass_website.cf_domain_name : ""
  description = "The domain name of the CloudFront distribution serving the Yopass website."
}

output "website_cloudfront_hosted_zone_id" {
  value       = module.yopass_label.enabled ? module.yopass_website.cf_hosted_zone_id : ""
  description = "The hosted zone id of the CloudFront distribution serving the Yopass website."
}

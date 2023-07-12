output "lambda_fn_arn" {
  value = local.enabled ? aws_lambda_function.this[0].arn : ""
}

output "lambda_fn_execution_url" {
  value = local.enabled ? aws_lambda_function_url.this[0].function_url : ""
}

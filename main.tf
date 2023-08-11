locals {
  name            = coalesce(module.this.name, var.name, "yopass-${random_string.yopass_random_suffix.result}")
  aws_account_id  = try(coalesce(var.aws_account_id, data.aws_caller_identity.current[0].account_id), "") # tflint-ignore: terraform_unused_declarations
  aws_region_name = try(coalesce(var.aws_region_name, data.aws_region.current[0].name), "")

  yopass_server_apigw_url = module.yopass_label.enabled ? aws_api_gateway_stage.this[0].invoke_url : ""
}

data "aws_caller_identity" "current" {
  count = module.this.enabled && var.aws_account_id == "" ? 1 : 0
}

data "aws_region" "current" {
  count = module.this.enabled && var.aws_region_name == "" ? 1 : 0
}

# =================================================================== yopass ===

module "yopass_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name    = local.name
  context = module.this.context
}

# only appliable if name variable was not set
resource "random_string" "yopass_random_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ------------------------------------------------------------------ website ---

module "yopass_website_assets" {
  source  = "cruxstack/artifact-packager/docker"
  version = "1.3.6"

  attributes             = ["website"]
  artifact_src_path      = "/tmp/package.zip"
  artifact_dst_directory = "${path.module}/dist"
  docker_build_context   = abspath("${path.module}/assets/yopass-website")
  docker_build_target    = "package"

  docker_build_args = {
    YOPASS_VERSION      = var.yopass_version
    YOPASS_FRONTEND_URL = "https://${var.website_domain_name}"
    YOPASS_BACKEND_URL  = trim(local.yopass_server_apigw_url, "/")
  }

  context = module.yopass_label.context
}

module "yopass_website" {
  source  = "cloudposse/cloudfront-s3-cdn/aws"
  version = "0.92.0"

  aliases             = [var.website_domain_name]
  acm_certificate_arn = var.website_certificate_arn
  dns_alias_enabled   = false
  web_acl_id          = try(data.aws_wafv2_web_acl.website[0].arn, "")

  cache_policy_id            = var.auth_enabled ? try(data.aws_cloudfront_cache_policy.disabled[0].id) : try(data.aws_cloudfront_cache_policy.optimized[0].id)
  origin_request_policy_id   = try(data.aws_cloudfront_origin_request_policy.cors_s3origin[0].id)
  response_headers_policy_id = try(data.aws_cloudfront_response_headers_policy.cors_preflight_hsts[0].id)

  lambda_function_association = var.auth_enabled ? [
    {
      event_type   = "viewer-request"
      lambda_arn   = module.cloudfront_middleware_at_edge.auth_services.check_auth.fn_arn
      include_body = false
    },
  ] : []

  custom_origins = var.auth_enabled ? [{
    # blackhole (never served) origin assigned to auth-at-edge behaviors/paths
    domain_name    = "blackhole.example.com"
    origin_id      = "blackhole"
    origin_path    = ""
    custom_headers = []
    custom_origin_config = {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 60
      origin_read_timeout      = 60
    }
  }] : []

  ordered_cache = var.auth_enabled ? [
    for x in module.cloudfront_middleware_at_edge.auth_routes : {
      target_origin_id            = "blackhole"
      path_pattern                = x.path_pattern
      allowed_methods             = x.allowed_methods
      compress                    = x.compress
      cache_policy_id             = x.cache_policy
      origin_request_policy_id    = x.origin_request_policy
      response_headers_policy_id  = x.response_headers_policy
      lambda_function_association = x.lambda_function_association
      viewer_protocol_policy      = x.viewer_protocol_policy

      // using cf policies so these are not used but are required to be defined
      cached_methods                    = ["GET", "HEAD"]
      default_ttl                       = null
      forward_cookies                   = null
      forward_cookies_whitelisted_names = null
      forward_header_values             = null
      forward_query_string              = null
      function_association              = []
      max_ttl                           = null
      min_ttl                           = null
      trusted_key_groups                = null
      trusted_signers                   = null
  }] : []

  cloudfront_access_log_create_bucket = false
  cloudfront_access_logging_enabled   = false
  s3_access_logging_enabled           = false
  versioning_enabled                  = false

  context = module.yopass_label.context
}

module "yopass_website_uploader" {
  source  = "cruxstack/s3-zip-uploader/aws"
  version = "1.3.0"

  artifact_dst_bucket_arn = module.yopass_website.s3_bucket_arn
  artifact_src_local_path = module.yopass_website_assets.artifact_package_path

  context = module.yopass_label.context

  depends_on = [
    module.yopass_website_assets,
  ]
}

data "aws_wafv2_web_acl" "website" {
  count = module.yopass_label.enabled && var.website_waf_acl_name != "" ? 1 : 0

  name  = var.website_waf_acl_name
  scope = "CLOUDFRONT"
}

data "aws_cloudfront_cache_policy" "disabled" {
  count = module.yopass_label.enabled ? 1 : 0
  name  = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "optimized" {
  count = module.yopass_label.enabled ? 1 : 0
  name  = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "cors_s3origin" {
  count = module.yopass_label.enabled ? 1 : 0
  name  = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_response_headers_policy" "cors_preflight_hsts" {
  count = module.yopass_label.enabled ? 1 : 0
  name  = "Managed-CORS-with-preflight-and-SecurityHeadersPolicy"
}

# ------------------------------------------------------------- website-auth ---

module "cloudfront_middleware_at_edge" {
  source  = "cruxstack/cloudfront-middleware-at-edge/aws"
  version = "0.3.3"

  enabled    = var.auth_enabled
  attributes = ["mw"]

  auth_service_config = {
    enabled                   = var.auth_enabled
    aws_region                = local.aws_region_name
    log_level                 = "info"
    cognito_idp_arn           = var.auth_cognito_idp_arn
    cognito_idp_domain        = var.auth_cognito_idp_domain
    cognito_idp_client_id     = var.auth_cognito_idp_client_id
    cognito_idp_client_secret = var.auth_cognito_idp_client_secret
    cognito_idp_client_scopes = var.auth_cognito_idp_client_scopes
    cognito_idp_jwks          = var.auth_cognito_idp_jwks
  }

  context = module.yopass_label.context
}

# ------------------------------------------------------------------- server ---

module "yopass_server_code" {
  source  = "cruxstack/artifact-packager/docker"
  version = "1.3.6"

  attributes             = ["server"]
  artifact_src_path      = "/tmp/package.zip"
  artifact_dst_directory = "${path.module}/dist"
  docker_build_context   = abspath("${path.module}/assets/yopass-server")
  docker_build_target    = "package"
  force_rebuild_id       = 1

  docker_build_args = {
    "YOPASS_VERSION" = var.yopass_version
  }

  context = module.yopass_label.context
}

resource "aws_cloudwatch_log_group" "this" {
  count = module.yopass_label.enabled ? 1 : 0

  name              = "/aws/lambda/${module.yopass_label.id}"
  retention_in_days = 90

  tags = module.yopass_label.tags
}

resource "aws_lambda_function" "this" {
  count = module.yopass_label.enabled ? 1 : 0

  function_name = module.yopass_label.id
  filename      = module.yopass_server_code.artifact_package_path
  handler       = "main"
  runtime       = "go1.x"
  timeout       = 45
  role          = aws_iam_role.this[0].arn
  layers        = []

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.this[0].name
      MAX_LENGTH = var.yopass_encrypted_secret_max_length
    }
  }

  tags = module.yopass_label.tags

  depends_on = [
    module.yopass_server_code,
    aws_cloudwatch_log_group.this,
  ]
}

resource "aws_api_gateway_rest_api" "this" {
  count = module.yopass_label.enabled ? 1 : 0

  name        = module.yopass_label.id
  description = "YoPass Server API"
  tags        = module.yopass_label.tags
}

resource "aws_api_gateway_resource" "proxy" {
  count = module.yopass_label.enabled ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.this[0].id
  parent_id   = aws_api_gateway_rest_api.this[0].root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  count = module.yopass_label.enabled ? 1 : 0

  rest_api_id   = aws_api_gateway_rest_api.this[0].id
  resource_id   = aws_api_gateway_resource.proxy[0].id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  count = module.yopass_label.enabled ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.this[0].id
  resource_id = aws_api_gateway_method.proxy[0].resource_id
  http_method = aws_api_gateway_method.proxy[0].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this[0].invoke_arn
}

resource "aws_api_gateway_deployment" "this" {
  count = module.yopass_label.enabled ? 1 : 0

  rest_api_id       = aws_api_gateway_rest_api.this[0].id
  stage_description = "live"

  depends_on = [
    aws_api_gateway_integration.lambda
  ]
}

resource "aws_api_gateway_stage" "this" {
  count = module.yopass_label.enabled ? 1 : 0

  deployment_id = aws_api_gateway_deployment.this[0].id
  rest_api_id   = aws_api_gateway_rest_api.this[0].id
  stage_name    = "live"

  depends_on = [
    aws_api_gateway_deployment.this
  ]
}

resource "aws_lambda_permission" "apigw" {
  count = module.yopass_label.enabled ? 1 : 0

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this[0].execution_arn}/*/*"
}

resource "aws_wafv2_web_acl_association" "this" {
  count = module.yopass_label.enabled && var.server_waf_acl_name != "" ? 1 : 0

  resource_arn = aws_api_gateway_stage.this[0].arn
  web_acl_arn  = data.aws_wafv2_web_acl.server[0].arn
}

data "aws_wafv2_web_acl" "server" {
  count = module.yopass_label.enabled && var.server_waf_acl_name != "" ? 1 : 0

  name  = var.server_waf_acl_name
  scope = "REGIONAL"
}

# ---------------------------------------------------------------------- ddb ---

resource "aws_dynamodb_table" "this" {
  count = module.yopass_label.enabled ? 1 : 0

  name         = module.yopass_label.id
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = module.yopass_label.tags
}

# ---------------------------------------------------------------------- iam ---

resource "aws_iam_role" "this" {
  count = module.yopass_label.enabled ? 1 : 0

  name        = module.yopass_label.id
  description = ""

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { "Service" : "lambda.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policy {
    name   = "access"
    policy = data.aws_iam_policy_document.this[0].json
  }

  tags = module.yopass_label.tags
}

data "aws_iam_policy_document" "this" {
  count = module.yopass_label.enabled ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
    ]
    resources = [
      aws_dynamodb_table.this[0].arn,
    ]
  }
}

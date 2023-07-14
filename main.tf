locals {
  aws_account_id  = try(coalesce(var.aws_account_id, data.aws_caller_identity.current[0].account_id), "")
  aws_region_name = try(coalesce(var.aws_region_name, data.aws_region.current[0].name), "")

  yopass_server_api_endpoint = module.yopass_label.enabled ? aws_api_gateway_deployment.this[0].invoke_url : ""
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

  name    = coalesce(module.this.name, var.name, "yopass-${random_string.yopass_random_suffix.result}")
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
  source  = "sgtoj/artifact-packager/docker"
  version = "1.2.3"

  attributes             = ["website"]
  artifact_src_path      = "/tmp/package.zip"
  artifact_dst_directory = "${path.module}/dist"
  docker_build_context   = abspath("${path.module}/assets/yopass-website")
  docker_build_target    = "package"

  docker_build_args = {
    YOPASS_VERSION      = var.yopass_version
    YOPASS_FRONTEND_URL = "https://${var.website_domain_name}"
    YOPASS_BACKEND_URL  = trim(local.yopass_server_api_endpoint, "/")
  }

  context = module.yopass_label.context
}

module "yopass_website" {
  source  = "cloudposse/cloudfront-s3-cdn/aws"
  version = "0.90.0"

  aliases             = [var.website_domain_name]
  acm_certificate_arn = var.website_certificate_arn
  dns_alias_enabled   = false
  web_acl_id          = var.website_waf_acl_id

  cloudfront_access_log_create_bucket = false
  cloudfront_access_logging_enabled   = false
  s3_access_logging_enabled           = false
  versioning_enabled                  = false

  context = module.yopass_label.context
}

module "yopass_website_uploader" {
  source  = "sgtoj/s3-zip-uploader/aws"
  version = "1.0.1"

  artifact_dst_bucket_arn = module.yopass_website.s3_bucket_arn
  artifact_src_local_path = module.yopass_website_assets.artifact_package_path

  context = module.yopass_label.context

  depends_on = [
    module.yopass_website_assets,
  ]
}

# ------------------------------------------------------------------- server ---

module "yopass_server_code" {
  source  = "sgtoj/artifact-packager/docker"
  version = "1.2.3"

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
  count             = module.yopass_label.enabled ? 1 : 0
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
  description = "YoPass API"
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

  rest_api_id = aws_api_gateway_rest_api.this[0].id
  stage_name  = "live"

  depends_on = [
    aws_api_gateway_integration.lambda
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

locals {
  enabled         = module.this.enabled
  aws_account_id  = try(coalesce(var.aws_account_id, data.aws_caller_identity.current[0].account_id), "")
  aws_region_name = try(coalesce(var.aws_region_name, data.aws_caller_identity.current[0].region), "")
}

data "aws_caller_identity" "current" {
  count = local.enabled && (var.aws_account_id == "" || var.aws_region_name == "") ? 1 : 0
}

# =================================================================== yopass ===

module "yopass_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name    = var.name == "" ? "yopass" : var.name
  context = module.this.context
}

# ------------------------------------------------------------------- server ---

module "yopass_server_code" {
  source  = "sgtoj/artifact-packager/docker"
  version = "1.0.0"

  artifact_src_path    = "/tmp/package.zip"
  docker_build_args    = { "YOPASS_VERSION" = var.yopass_version }
  docker_build_context = abspath("${path.module}/assets/yopass-server")
  docker_build_target  = "package"

  context = module.yopass_label.context
}

resource "aws_cloudwatch_log_group" "this" {
  count             = local.enabled ? 1 : 0
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
    module.yopass_code,
    aws_cloudwatch_log_group.this,
  ]
}

resource "aws_lambda_function_url" "this" {
  count = module.yopass_label.enabled ? 1 : 0

  function_name      = aws_lambda_function.aws_lambda_function[0].function_name
  authorization_type = "NONE"
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
  count = local.enabled ? 1 : 0

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
  count = local.enabled ? 1 : 0

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

locals {
  domain_name                  = var.domain_name
  domain_parent_hosted_zone_id = var.domain_parent_hosted_zone_id
}

# ================================================================== example ===

module "cognito_user_pool_client" {
  source  = "rallyware/cognito-user-pool-client/aws"
  version = "0.2.0"

  user_pool_id                         = module.cognito_user_pool.id
  allowed_oauth_flows_user_pool_client = true
  generate_secret                      = true
  allowed_oauth_flows                  = ["code", ]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  callback_urls                        = ["https://${local.domain_name}/_edge/auth/signin"]
  logout_urls                          = ["https://google.com"]
  supported_identity_providers         = ["COGNITO"]

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
  ]

  context = module.example_label.context
}

module "yopass" {
  source = "../../"

  website_domain_name     = local.domain_name
  website_certificate_arn = module.ssl_certificate.arn

  auth_enabled                   = true
  auth_cognito_idp_arn           = module.cognito_user_pool.arn
  auth_cognito_idp_domain        = "${aws_cognito_user_pool_domain.this.domain}.auth.us-east-1.amazoncognito.com"
  auth_cognito_idp_client_id     = module.cognito_user_pool_client.id
  auth_cognito_idp_client_secret = module.cognito_user_pool_client.client_secret
  auth_cognito_idp_client_scopes = ["openid", "email", "profile"]
  auth_cognito_idp_jwks          = jsondecode(data.http.cognito_user_pool_jwks.response_body)

  context = module.example_label.context
}

# ===================================================== supporting-resources ===

module "example_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  enabled = true
  name    = "eg-yopass-${random_string.example_random_suffix.result}"
  tags    = { tf_module = "cruxstack/yopass/aws", tf_module_example = "complete-with-auth" }
  context = module.this.context
}

resource "random_string" "example_random_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ---------------------------------------------------------------------- dns ---

module "dns" {
  source  = "cloudposse/route53-alias/aws"
  version = "0.13.0"

  aliases         = [local.domain_name]
  parent_zone_id  = local.domain_parent_hosted_zone_id
  target_dns_name = module.yopass.website_cloudfront_domain_name
  target_zone_id  = module.yopass.website_cloudfront_hosted_zone_id
  ipv6_enabled    = false

  context = module.example_label.context
}

module "ssl_certificate" {
  source  = "cloudposse/acm-request-certificate/aws"
  version = "0.17.0"

  domain_name                       = local.domain_name
  process_domain_validation_options = true
  ttl                               = "60"
  zone_id                           = local.domain_parent_hosted_zone_id

  tags    = merge(module.example_label.tags, { Name = module.example_label.id })
  context = module.example_label.context
}

# ------------------------------------------------------------------ cognito ---

module "cognito_user_pool" {
  source  = "lgallard/cognito-user-pool/aws"
  version = "0.22.0"

  user_pool_name           = module.example_label.id
  alias_attributes         = []
  auto_verified_attributes = []
  deletion_protection      = "INACTIVE"

  admin_create_user_config = {
    allow_admin_create_user_only = true
  }

  tags = module.example_label.tags
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = module.example_label.id
  user_pool_id = module.cognito_user_pool.id
}

resource "random_password" "test_user_password" {
  special          = true
  override_special = "!#$-_=+"
  length           = 16
  min_numeric      = 1
  min_lower        = 1
  min_upper        = 1
  min_special      = 1
}

resource "aws_cognito_user" "test_user" {
  user_pool_id = module.cognito_user_pool.id
  username     = "test@example.com"
  password     = random_password.test_user_password.result
  enabled      = true
}

data "http" "cognito_user_pool_jwks" {
  url = "https://${module.cognito_user_pool.endpoint}/.well-known/jwks.json"
}

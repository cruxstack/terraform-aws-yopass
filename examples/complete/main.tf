locals {
  name = "tf-example-complete-${random_string.example_random_suffix.result}"
  tags = { tf_module = "cruxstack/yopass/aws", tf_module_example = "complete" }

  domain_name                  = var.domain_name
  domain_parent_hosted_zone_id = var.domain_parent_hosted_zone_id
}

# =================================================================== yopass ===

module "yopass" {
  source = "../../"

  website_domain_name     = local.domain_name
  website_certificate_arn = module.ssl_certificate.arn

  context = module.example_label.context
}

# ===================================================== supporting-resources ===

module "example_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name        = local.name
  environment = "use1" # us-east-1
  tags        = local.tags

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

  context = module.example_label.context
  tags    = merge(module.example_label.tags, { Name = module.this.id })
}

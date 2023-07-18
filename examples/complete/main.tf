locals {
  domain_name                  = var.domain_name
  domain_parent_hosted_zone_id = var.domain_parent_hosted_zone_id
}

# =================================================================== yopass ===

module "yopass" {
  source = "../../"

  website_domain_name     = local.domain_name
  website_certificate_arn = module.ssl_certificate.arn

  tags = { tf_module = "sgtoj/yopass/aws", tf_module_example = "complete" }
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

  context = module.this.context
}

module "ssl_certificate" {
  source  = "cloudposse/acm-request-certificate/aws"
  version = "0.17.0"

  domain_name                       = local.domain_name
  process_domain_validation_options = true
  ttl                               = "60"
  zone_id                           = local.domain_parent_hosted_zone_id

  tags    = merge(module.this.tags, { Name = module.this.id })
  context = module.this.context
}

variable "domain_name" {
  description = "The domain name to use for the Yopass website."
  type        = string
}

variable "domain_parent_hosted_zone_id" {
  description = "The ID of the Route 53 hosted zone for the domain name."
  type        = string
}

# ================================================================== general ===

variable "yopass_encrypted_secret_max_length" {
  type        = number
  description = "Maximum length of encrypted secrets."
  default     = 10000

  validation {
    condition     = can(regex("^[1-9][0-9]*$", var.yopass_encrypted_secret_max_length))
    error_message = "Must be a positive integer"
  }
}

variable "yopass_version" {
  type        = string
  description = "Version of Yopass to deploy."
  default     = "latest"
}

variable "server_waf_acl_name" {
  type        = string
  description = "Name of the WAF ACL to associate with the API Gateway."
  default     = ""
}

variable "website_domain_name" {
  type        = string
  description = "Domain name for Yopass website."
}

variable "website_certificate_arn" {
  type        = string
  description = "ARN of the ACM certificate for the domain name."
}

variable "website_waf_acl_name" {
  type        = string
  description = "Name of the WAF ACL to associate with the CloudFront distribution."
  default     = ""
}

# -------------------------------------------------------------------- auth ---

variable "auth_enabled" {
  type        = bool
  description = "Whether to enable authentication power by Cognito User Pool."
  default     = false
}

variable "auth_cognito_idp_arn" {
  type        = string
  description = "ARN of the Cognito User Pool to use for authentication. Only appliable if `auth_enabled` is `true`."
  default     = null
}

variable "auth_cognito_idp_domain" {
  type        = string
  description = "Domain of the Cognito User Pool to use for authentication. Only appliable if `auth_enabled` is `true`."
  default     = null
}

variable "auth_cognito_idp_client_id" {
  type        = string
  description = "Client ID of the Cognito User Pool to use for authentication. Only appliable if `auth_enabled` is `true`."
  default     = null
}

variable "auth_cognito_idp_client_secret" {
  type        = string
  description = "Client secret of the Cognito User Pool to use for authentication. Only appliable if `auth_enabled` is `true`."
  default     = null
}

variable "auth_cognito_idp_client_scopes" {
  type        = list(string)
  description = "Client scopes of the Cognito User Pool to use for authentication. Only appliable if `auth_enabled` is `true`."
  default     = []
}

variable "auth_cognito_idp_jwks" {
  type        = object({ keys = list(map(string)) })
  description = "JWKS of the Cognito User Pool to use for authentication. Only appliable if `auth_enabled` is `true`."
  default     = null
}

# ------------------------------------------------------------------ context ---

variable "aws_account_id" {
  description = "The AWS account ID that the module will be deployed."
  type        = string
  default     = ""
}

variable "aws_region_name" {
  description = "The AWS region name where the module will be deployed."
  type        = string
  default     = ""
}

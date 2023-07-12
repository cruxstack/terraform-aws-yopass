# ================================================================== general ===

variable "yopass_encrypted_secret_max_length" {
  type        = number
  description = "Maximum length of encrypted secrets"
  default     = 10000

  validation {
    condition     = can(regex("^[1-9][0-9]*$", var.yopass_encrypted_secret_max_length))
    error_message = "Must be a positive integer"
  }
}

variable "yopass_version" {
  type        = string
  description = "Version of Yopass to deploy"
  default     = "latest"
}

# ------------------------------------------------------------------ context ---

variable "aws_account_id" {
  description = "The AWS account ID that the module will be deployed in."
  type        = string
  default     = ""
}

variable "aws_region_name" {
  description = "The AWS region name where the module will be deployed."
  type        = string
  default     = ""
}

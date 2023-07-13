
# ================================================================== general ===

variable "artifact_src_bucket_arn" {
  type = string
}

variable "artifact_src_bucket_path" {
  type = string
}

variable "artifact_src_local_path" {
  type = string
}

variable "artifact_dst_bucket_arn" {
  type = string
}

variable "artifact_dst_bucket_path" {
  type    = string
  default = "/"
}

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "app_id" {
  type = string
}

variable "s3_src_bucket_name" {
  description = "S3 src bucket name to scan"
  type        = string
}

variable "s3_src_bucket_arn" {
  description = "S3 src bucket ARN to scan"
  type        = string
}

variable "s3_quarantine_bucket_name" {
  description = "S3 quarantine bucket name for flagged content"
  type        = string
  default     = "quarantine-bucket"
}

variable "admin_email" {
  description = "Admin email to send notifications to"
  type        = string
}

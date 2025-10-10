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

variable "s3_bucket_name" {
  description = "S3 bucket name to scan"
  type = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN to scan"
  type = string
}

variable "admin_email" {
  description = "Admin email to send notifications to"
  type = string
}

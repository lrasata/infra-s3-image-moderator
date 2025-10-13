module "s3_image_moderator" {
  source = "./modules/s3_image_moderator"

  region                    = var.region
  environment               = var.environment #
  s3_src_bucket_name        = var.s3_bucket_name
  s3_src_bucket_arn         = var.s3_bucket_arn
  s3_quarantine_bucket_name = var.s3_quarantine_bucket_name
  admin_email               = var.admin_email
}
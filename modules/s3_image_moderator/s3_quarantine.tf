resource "aws_s3_bucket" "s3_quarantine_bucket" {
  bucket = "${var.environment}-${var.s3_quarantine_bucket_name}"
}

# S3 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "quarantine_encryption" {
  bucket = aws_s3_bucket.s3_quarantine_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_cmk.arn
    }
  }
}


#  Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "s3_quarantine_bucket_public_access" {
  bucket                  = aws_s3_bucket.s3_quarantine_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
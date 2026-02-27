data "aws_caller_identity" "current" {}

resource "aws_kms_key" "s3_cmk" {
  description         = "CMK for quarantine bucket and access logs"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow root account full access
      {
        Sid    = "AllowRootAccount"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },

      # Allow S3 logging to use the key
      {
        Sid    = "AllowS3Logging"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      # Lambda role for content moderation
      {
        Sid       = "AllowLambdaImageModeratorUse",
        Effect    = "Allow",
        Principal = { AWS = aws_iam_role.lambda_image_moderator_exec_role.arn },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ],
        Resource = "*"
      },

      # Lambda role access for S3 copy
      {
        Sid       = "AllowLambdaUse"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.lambda_move_to_quarantine_exec_role.arn }
        Action    = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey"]
        Resource  = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "s3_cmk_alias" {
  name          = "alias/${var.environment}-${var.app_id}-image-moderation-s3-cmk"
  target_key_id = aws_kms_key.s3_cmk.id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_target_sse" {
  bucket = aws_s3_bucket.quarantine_log_target.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_cmk.arn
    }
  }
}
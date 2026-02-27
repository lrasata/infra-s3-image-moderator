resource "aws_kms_key" "sns_cmk" {
  description         = "SNS CMK"
  enable_key_rotation = true
  tags = {
    Environment = var.environment
    App         = var.app_id
  }

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow root account full access
      {
        Sid    = "AllowRootAccount"
        Effect = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action   = "kms:*"
        Resource = "*"
      },

      # Allow Lambda to publish
      {
        Sid       = "AllowLambdaUse"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.lambda_image_moderator_exec_role.arn }
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ]
        Resource = "*"
      },

      # Allow SNS service to use the key
      {
        Sid       = "AllowSNSUse"
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = [
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_sns_topic" "scan_alerts" {
  name = "${var.environment}-${var.app_id}-inappropriate-image-alerts"

  kms_master_key_id = aws_kms_key.sns_cmk.arn

  tags = {
    Service     = "image-moderation"
    Environment = var.environment
    App         = var.app_id
  }
}

resource "aws_sns_topic_subscription" "admin_email" {
  topic_arn = aws_sns_topic.scan_alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email
}

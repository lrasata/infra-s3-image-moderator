resource "aws_kms_key" "sns_cmk" {
  description         = "SNS CMK"
  enable_key_rotation = true
  tags = {
    Environment = var.environment
    App         = var.app_id
  }
}

resource "aws_sns_topic" "scan_alerts" {
  name = "${var.environment}-inappropriate-image-alerts"

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

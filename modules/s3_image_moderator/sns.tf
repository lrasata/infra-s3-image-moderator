resource "aws_sns_topic" "scan_alerts" {
  name = "${var.environment}-inappropriate-image-alerts"
}

resource "aws_sns_topic_subscription" "admin_email" {
  topic_arn = aws_sns_topic.scan_alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email
}

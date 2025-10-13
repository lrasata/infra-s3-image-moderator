### s3 daily scan to detect inappropriate images
resource "aws_cloudwatch_event_rule" "daily_scan_image_moderation" {
  name                = "${var.environment}-daily-scan-s3-image-moderation"
  schedule_expression = "rate(24 hours)"
}

resource "aws_cloudwatch_event_target" "lambda_image_moderator_target" {
  rule      = aws_cloudwatch_event_rule.daily_scan_image_moderation.name
  target_id = "lambda"
  arn       = aws_lambda_function.lambda_image_moderator.arn
}

resource "aws_lambda_permission" "im_allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_image_moderator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_scan_image_moderation.arn
}

### s3 daily scan to move tagged images to quarantine bucket
resource "aws_cloudwatch_event_rule" "daily_scan_move_to_quarantine" {
  name                = "${var.environment}-daily-scan-s3-move-to-quarantine"
  schedule_expression = "rate(24 hours)"
}

resource "aws_cloudwatch_event_target" "lambda_move_to_quarantine_target" {
  rule      = aws_cloudwatch_event_rule.daily_scan_move_to_quarantine.name
  target_id = "lambda"
  arn       = aws_lambda_function.lambda_move_to_quarantine.arn
}

resource "aws_lambda_permission" "mq_allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_move_to_quarantine.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_scan_move_to_quarantine.arn
}


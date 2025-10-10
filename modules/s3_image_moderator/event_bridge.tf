resource "aws_cloudwatch_event_rule" "daily_scan" {
  name                = "daily-s3-image-scan"
  schedule_expression = "rate(24 hours)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_scan.name
  target_id = "lambda"
  arn       = aws_lambda_function.lambda_image_moderator.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_image_moderator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_scan.arn
}


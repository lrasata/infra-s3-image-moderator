data "archive_file" "lambda_image_moderator_zip" {
  type       = "zip"
  source_dir = "${path.module}/lambada_image_moderation"
  output_path = "${path.module}/lambada_image_moderation.zip"
}

resource "aws_iam_role" "lambda_image_moderator_exec_role" {
  name = "${var.environment}-lambda-image-moderation-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_lambda_function" "lambda_image_moderator" {
  function_name = "${var.environment}-image-moderator-lambda"
  runtime       = "python3.12"
  handler       = "image_moderation_handler.handler"

  filename         = data.archive_file.lambda_image_moderator_zip.output_path
  source_code_hash = data.archive_file.lambda_image_moderator_zip.output_base64sha256

  role = aws_iam_role.lambda_image_moderator_exec_role.arn

  timeout     = 30  # seconds

  environment {
    variables = {
      BUCKET_NAME = var.s3_bucket_name
      SNS_TOPIC_ARN = aws_sns_topic.scan_alerts.arn
    }
  }
}


resource "aws_iam_policy" "lambda_image_moderator_policy" {
  name        = "${var.environment}-lambda-process-uploaded-file-policy"
  description = "Allow Lambda to access S3 upload bucket for read and update"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "rekognition:DetectModerationLabels"
        ],
        Resource = ["*"]
      },
      {
        Action = ["s3:GetObject", "s3:ListBucket"]
        Effect = "Allow"
        Resource = [
          "${var.s3_bucket_arn}/*",
          "${var.s3_bucket_arn}"
        ]
      },
      {
        Action = ["sns:Publish"]
        Effect = "Allow"
        Resource = [aws_sns_topic.scan_alerts.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_im_access_policy_attach" {
  role       = aws_iam_role.lambda_image_moderator_exec_role.name
  policy_arn = aws_iam_policy.lambda_image_moderator_policy.arn
}

# Give lambda minimal permissions including : logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents
resource "aws_iam_role_policy_attachment" "lambda_im_logs_policy" {
  role       = aws_iam_role.lambda_image_moderator_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
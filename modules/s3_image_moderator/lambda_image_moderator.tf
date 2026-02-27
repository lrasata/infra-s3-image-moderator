data "archive_file" "lambda_image_moderator_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_image_moderator"
  output_path = "${path.module}/lambda_image_moderator.zip"
}

resource "aws_iam_role" "lambda_image_moderator_exec_role" {
  name = "${var.environment}-${var.app_id}-lambda-image-moderator-exec-role"

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
  function_name = "${var.environment}-${var.app_id}-image-moderator-lambda"
  runtime       = "python3.12"
  handler       = "image_moderator_handler.handler"

  filename         = data.archive_file.lambda_image_moderator_zip.output_path
  source_code_hash = data.archive_file.lambda_image_moderator_zip.output_base64sha256

  role = aws_iam_role.lambda_image_moderator_exec_role.arn

  timeout = 30 # seconds

  environment {
    variables = {
      BUCKET_NAME   = var.s3_src_bucket_name
      SNS_TOPIC_ARN = aws_sns_topic.scan_alerts.arn
    }
  }
}


resource "aws_iam_policy" "lambda_image_moderator_policy" {
  name        = "${var.environment}-${var.app_id}-lambda-image-moderator-policy"
  description = "Allow Lambda to access S3 upload bucket and publish to SNS topic"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "rekognition:DetectModerationLabels"
        ],
        Resource = "*"
      },
      {
        Action = ["s3:GetObject", "s3:GetObjectTagging", "s3:ListBucket", "s3:PutObjectTagging"]
        Effect = "Allow"
        Resource = [
          "${var.s3_src_bucket_arn}/*",
          "${var.s3_src_bucket_arn}"
        ]
      },
      {
        Action   = ["sns:Publish"]
        Effect   = "Allow"
        Resource = [aws_sns_topic.scan_alerts.arn]
      },
      # KMS access for encrypted SNS topic
      {
        Effect   = "Allow"
        Action   = ["kms:GenerateDataKey", "kms:Encrypt"]
        Resource = aws_kms_key.sns_cmk.arn
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
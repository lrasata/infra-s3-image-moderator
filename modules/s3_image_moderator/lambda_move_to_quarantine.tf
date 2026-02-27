data "archive_file" "lambda_move_to_quarantine_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_move_to_quarantine"
  output_path = "${path.module}/lambda_move_to_quarantine.zip"
}

resource "aws_iam_role" "lambda_move_to_quarantine_exec_role" {
  name = "${var.environment}-lambda-move-to-quarantine-exec-role"

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

resource "aws_lambda_function" "lambda_move_to_quarantine" {
  function_name = "${var.environment}-move-to-quarantine-lambda"
  runtime       = "python3.12"
  handler       = "move_to_quarantine_handler.handler"

  filename         = data.archive_file.lambda_move_to_quarantine_zip.output_path
  source_code_hash = data.archive_file.lambda_move_to_quarantine_zip.output_base64sha256

  role = aws_iam_role.lambda_move_to_quarantine_exec_role.arn

  timeout = 30 # seconds

  environment {
    variables = {
      SOURCE_BUCKET     = var.s3_src_bucket_name
      QUARANTINE_BUCKET = aws_s3_bucket.s3_quarantine_bucket.id
    }
  }
}


resource "aws_iam_policy" "lambda_move_to_quarantine_policy" {
  name        = "${var.environment}-lambda-move-to-quarantine-policy"
  description = "Allow Lambda to access S3 upload bucket and move objects to quarantine bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:CopyObject", "s3:PutObject", "s3:PutObjectTagging"]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.s3_quarantine_bucket.arn}/*",
          aws_s3_bucket.s3_quarantine_bucket.arn
        ]
      },
      {
        Action = ["s3:GetObject", "s3:GetObjectTagging", "s3:ListBucket", "s3:DeleteObject"]
        Effect = "Allow"
        Resource = [
          "${var.s3_src_bucket_arn}/*",
          var.s3_src_bucket_arn
        ]
      },
      {
        Effect = "Allow"
        Action = ["kms:GenerateDataKey", "kms:Decrypt", "kms:Encrypt"]
        Resource = [
          "${aws_s3_bucket.s3_quarantine_bucket.arn}/*",
          aws_s3_bucket.s3_quarantine_bucket.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_mq_access_policy_attach" {
  role       = aws_iam_role.lambda_move_to_quarantine_exec_role.name
  policy_arn = aws_iam_policy.lambda_move_to_quarantine_policy.arn
}

# Give lambda minimal permissions including : logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents
resource "aws_iam_role_policy_attachment" "lambda_mq_logs_policy" {
  role       = aws_iam_role.lambda_move_to_quarantine_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role" "lambda_exec_role" {
  name = "terraform-cloud-webhook-receiver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_exec_role.name
}

resource "aws_iam_policy" "lambda_policy" {
  name = "terraform-cloud-webhook-receiver"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatch"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        "Resource" : [
          aws_cloudwatch_log_group.lambda_logs.arn,
          "${aws_cloudwatch_log_group.lambda_logs.arn}:log-stream:*",
        ]
      },
      {
        Sid    = "ParameterStore"
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = [
          aws_ssm_parameter.notification_hmac.arn
        ]
      },
      {
        Sid    = "ParameterStoreDecrypt"
        Effect = "Allow"
        Action = ["kms:Decrypt"]
        Resource = [
          data.aws_kms_alias.ssm.target_key_arn
        ]
      }
    ]
  })
}
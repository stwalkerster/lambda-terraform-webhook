resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 1
}

locals {
  function_path = "${path.module}/dist/function.zip"
}


resource "aws_lambda_function" "function" {
  function_name = local.function_name
  role          = aws_iam_role.lambda_exec_role.arn

  filename      = local.function_path
  handler       = "main.handler"
  runtime       = "python3.8"
  architectures = ["arm64"]

  source_code_hash = filebase64sha256(local.function_path)

  layers = [
    "arn:aws:lambda:eu-west-1:015030872274:layer:AWS-Parameters-and-Secrets-Lambda-Extension-Arm64:2",
  ]

  environment {
    variables = {
      TFE_HMAC    = local.hmac_path
      RABBIT_BASE = local.rabbit_base_path
    }
  }

  depends_on = [
    # data.archive_file.function_package,
    aws_cloudwatch_log_group.lambda_logs,
  ]
}


resource "aws_lambda_function_url" "function" {
  authorization_type = "NONE"
  function_name      = aws_lambda_function.function.function_name
}

#data "archive_file" "function_package" {
#  type        = "zip"
#  source_file = "${path.module}/main.py"
#  output_path = local.function_path
#}

resource "aws_ssm_parameter" "notification_hmac" {
  name  = local.hmac_path
  type  = "SecureString"
  value = "changeme"

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "rabbitmq_public" {
  for_each = {
    exchange = "aws.notification"
    host     = "mq.srv.stwalkerster.net"
    port     = "5671"
    username = "aws-notification"
    vhost    = "/"
  }

  name  = "${local.rabbit_base_path}/${each.key}"
  type  = "String"
  value = each.value

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "rabbitmq_password" {
  name  = "${local.rabbit_base_path}/password"
  type  = "SecureString"
  value = "changeme"

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
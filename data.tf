data "aws_kms_alias" "ssm" {
  name = aws_ssm_parameter.notification_hmac.key_id
}

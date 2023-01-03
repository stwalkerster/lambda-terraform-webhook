data "aws_kms_alias" "ssm" {
  name = aws_ssm_parameter.notification_hmac.key_id
}

data "tfe_workspace" "tfe" {
  for_each = var.tfe_workspaces

  name         = split("/", each.value)[1]
  organization = split("/", each.value)[0]
}
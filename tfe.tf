data "tfe_workspace" "acc_app" {
  name         = "application"
  organization = "enwikipedia-acc"
}

data "tfe_workspace" "acc_oauth" {
  name         = "oauth"
  organization = "enwikipedia-acc"
}

resource "tfe_notification_configuration" "acc_app" {
  name             = "stw lambda"
  enabled          = true
  destination_type = "generic"
  triggers         = [
    "run:created",
    "run:planning",
    "run:needs_attention",
    "run:applying",
    "run:completed",
    "run:errored",
    "assessment:drifted",
    "assessment:failed",
    # "assessment:check_failure", # bug?
  ]
  url              = aws_lambda_function_url.function.function_url
  workspace_id     = data.tfe_workspace.acc_app.id
  token = var.hmac
}

resource "tfe_notification_configuration" "acc_oauth" {
  name             = "stw lambda"
  enabled          = true
  destination_type = "generic"
  triggers         = [
    "run:created",
    "run:planning",
    "run:needs_attention",
    "run:applying",
    "run:completed",
    "run:errored",
    "assessment:drifted",
    "assessment:failed",
    # "assessment:check_failure", # bug?
  ]
  url              = aws_lambda_function_url.function.function_url
  workspace_id     = data.tfe_workspace.acc_oauth.id
  token = var.hmac
}

variable "hmac" {
  default = null
}
locals {
  function_name    = "terraform-cloud-webhook-receiver"
  hmac_path        = "/TerraformWebhook/lambda/tfe_hmac"
  rabbit_base_path = "/TerraformWebhook/lambda/rabbit"
  function_path    = "${path.module}/dist/function.zip"

  github_params = {
    hdr = "x-hub-signature-256", sig = "sha256", prefix = "sha256-", src = "github", dest = var.notification_destination
  }
  github_url = "${aws_lambda_function_url.function.function_url}?${join("&", [for k, v in local.github_params: "${urlencode(k)}=${urlencode(v)}" ])}"

  tfe_params = {
    hdr = "x-tfe-notification-signature", sig = "sha512", prefix = "", src = "terraformcloud", dest = var.notification_destination
  }
  tfe_url = "${aws_lambda_function_url.function.function_url}?${join("&", [for k, v in local.tfe_params: "${urlencode(k)}=${urlencode(v)}" ])}"
}

variable "notification_destination" {
  type    = string
  default = "##stwalkerster-development"
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "hmac" {
  type      = string
  sensitive = true
}

variable "tfe_workspaces" {
  type    = set(string)
  default = [
    "enwikipedia-acc/oauth",
    "enwikipedia-acc/application",
  ]
}

variable "github_repositories" {
  type    = set(string)
  default = [
    "sandbox",
  ]
}
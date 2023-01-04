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
    hdr  = "x-tfe-notification-signature", sig = "sha512", prefix = "", src = "terraformcloud",
    dest = "#wikipedia-en-accounts-devs"
  }
  tfe_url = "${aws_lambda_function_url.function.function_url}?${join("&", [for k, v in local.tfe_params: "${urlencode(k)}=${urlencode(v)}" ])}"
}

variable "role_arn" {
  description = "The role for Terraform to assume"
  type    = map(string)
  default = {
    default = null
  }
}

variable "notification_destination" {
  type        = string
  description = "The routing key for the messages on RabbitMQ"
  default     = "##stwalkerster-development"
}

variable "hmac" {
  type      = string
  sensitive = true
}

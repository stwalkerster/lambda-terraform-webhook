variable "github_token" {}

provider "github" {
  token = var.github_token
}

resource "github_repository_webhook" "sandbox" {
  repository = "sandbox"

  configuration {
    url          = "${aws_lambda_function_url.function.function_url}?hdr=x-hub-signature-256&sig=sha256&prefix=sha256%3d&src=github&dest=%23%23stwalkerster-development"
    content_type = "json"
    insecure_ssl = false
    secret       = var.hmac
  }

  active = true
  events = ["*"]
}

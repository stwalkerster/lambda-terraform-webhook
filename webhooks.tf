resource "tfe_notification_configuration" "tfe" {
  for_each = toset([for x in data.tfe_workspace.tfe : x.id])

  name             = "Helpmebot via AWS Lambda/RabbitMQ"
  enabled          = true
  destination_type = "generic"
  triggers         = [
    "run:created",
    "run:planning",
    "run:needs_attention",
    "run:applying",
    "run:completed",
    "run:errored",
    # "assessment:drifted",
    # "assessment:failed",
    # "assessment:check_failure", # bug?
  ]
  url          = local.tfe_url
  workspace_id = each.value
  token        = var.hmac
}

resource "github_repository_webhook" "github" {
  for_each = var.github_repositories
  repository = each.value

  configuration {
    url          = local.github_url
    content_type = "json"
    insecure_ssl = false
    secret       = var.hmac
  }

  active = true
  events = ["*"]
}

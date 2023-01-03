# lambda-terraform-webhook

This repository holds the code behind my Terraform and GitHub to RabbitMQ notification bridge.

This uses AWS Lambda to host a serverless function which acts as the webhook endpoint.

There's probably a *lot* that's hard-coded to my usecase here, so while you should feel free to re-use this, beware that
it may not work out-of-the-box.

## Installation
Create a GitHub personal access token with access to edit webhooks.

Create `secrets.auto.tfvars` and inside define the variables `hmac` and `github_token`. The former should be the shared
secret between TFE and this function.

Log in to TFE (`terraform login`).

Modify the variables `notification_destination`, `tfe_workspaces`, and `github_repositories` to suit your requirements.
You probably want to do this in another `*.auto.tfvars` file.

```shell
make
terraform init
terraform apply --auto-approve
```

Go to SSM parameter store, and change the values of the parameters to suit your usecase.

# lambda-terraform-webhook

This repository holds the code behind my Terraform and GitHub to RabbitMQ notification bridge.

This uses AWS Lambda to host a serverless function which acts as the webhook endpoint.

There's probably a *lot* that's hard-coded to my usecase here, so while you should feel free to re-use this, beware that
it may not work out-of-the-box.
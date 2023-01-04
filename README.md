# lambda-terraform-webhook

This repository holds the code behind my Terraform and GitHub to RabbitMQ notification bridge.

This uses AWS Lambda to host a serverless function which acts as the webhook endpoint.

There's probably a *lot* that's hard-coded to my usecase here, so while you should feel free to re-use this, beware that
it may not work out-of-the-box.

## Installation
Create `secrets.auto.tfvars` and inside define the variable `hmac`, which should be the shared
secret between TFE and this function.

Modify the variables `notification_destination` to suit your requirements. This is used as the routing key in RabbitMQ
You probably want to do this in another `*.auto.tfvars` file.

```shell
make
terraform init
terraform apply --auto-approve
```

Go to SSM parameter store, and change the values of the parameters to suit your usecase.

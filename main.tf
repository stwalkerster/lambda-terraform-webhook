terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.48"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.40.0"
    }
    github = {
      source  = "integrations/github"
      version = "5.12.0"
    }
  }

  backend "s3" {
    bucket = "stwalkerster-terraform-state"
    key    = "state/Sandbox/TerraformWebhook/terraform.tfstate"
    region = "eu-west-1"

    dynamodb_table = "terraform-state-lock"
  }

  required_version = "~> 1.3.6"
}

provider "aws" {
  region = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::265088867231:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = {
      Terraform   = "yes"
      Project     = "TerraformWebhook"
      Environment = "Sandbox"
    }
  }
}

provider "github" {
  token = var.github_token
}

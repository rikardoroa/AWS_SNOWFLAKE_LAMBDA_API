terraform {
  required_version = "~> 1.9.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60.0"
    }
  }


  backend "s3" {
    encrypt        = true
    key            = "terraform/state/terraform.tfstate"
    dynamodb_table = "terraform-lock-table"
    region         = "us-east-2"
  }

}
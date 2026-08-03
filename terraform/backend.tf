terraform {
  backend "s3" {
    bucket         = "bcb-infra-terraform-state"
    key            = "bcb-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "bcb-infra-terraform-locks"
    encrypt        = true
  }
}

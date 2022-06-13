provider "aws" {
  profile                  = var.aws_profile
  region                   = var.aws_region
  shared_credentials_files = [var.aws_credentials_file]
}


terraform {
  required_version = ">= 0.14.4"


  backend "s3" {
    bucket  = "myterraform-state-save"
    key     = "ceros-ski/terraform.tfstate"
    profile = "default"
    region  = "us-east-1"
    # dynamodb_table = var.aws_dynamodb_table
  }

}

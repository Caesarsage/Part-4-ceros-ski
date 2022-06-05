provider "aws" {
  profile                 = var.aws_profile
  region                  = var.aws_region
  shared_credentials_files = [var.aws_credentials_file]
}


terraform {
  required_version = ">= 0.14.4"
}

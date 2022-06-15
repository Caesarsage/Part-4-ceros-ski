provider "aws" {
  profile                  = var.aws_profile
  region                   = var.aws_region
  shared_credentials_files = [var.aws_credentials_file]
}


terraform {
  required_version = ">= 0.14.4"

  backend "s3" {
    bucket         = "terraform-state-ceros-ski-caesar"
    key            = "ceros-ski/production/network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform_lock"
    encrypt        = true
  }
}

module "network_module" {
  source                = "../../modules/network/index"
  environment           = var.environment
  availability_zones    = var.availability_zones
  private_subnets_count = var.private_subnets_count
  public_subnets_count  = var.public_subnets_count
  cidr_block            = var.cidr_block
}
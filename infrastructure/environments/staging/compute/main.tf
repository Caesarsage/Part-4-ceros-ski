provider "aws" {
  profile                  = var.aws_profile
  region                   = var.aws_region
  shared_credentials_files = [var.aws_credentials_file]
}


terraform {
  required_version = ">= 0.14.4"

  backend "s3" {
    bucket         = "terraform-state-ceros-ski-caesar"
    key            = "ceros-ski/staging/compute/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform_lock"
    encrypt        = true
  }
}

module "compute_module" {
  source                = "../../modules/compute/index"
  repository_url        = var.repository_url
  public_key            = var.public_key
  environment           = var.environment
  availability_zones    = var.availability_zones
  cidr_block            = var.cidr_block
  public_subnets_count  = var.public_subnets_count
  private_subnets_count = var.private_subnets_count
}

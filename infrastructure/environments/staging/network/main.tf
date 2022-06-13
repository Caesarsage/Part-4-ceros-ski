provider "aws" {
  profile                  = var.aws_profile
  region                   = var.aws_region
  shared_credentials_files = [var.aws_credentials_file]
}


terraform {
  required_version = ">= 0.14.4"

  backend "s3" {
    bucket         = "terraform-state-ceros-ski-caesar"
    key            = "ceros-ski/staging/network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform_lock"
    encrypt        = true
  }
}


# VPC

module "vpc_module" {
  source      = "../../modules/vpc"
  environment = var.environment
}


# INTERNET GATEWAY
module "internet_gateway_module" {
  source      = "../../modules/internet_gateway"
  vpc_id      = module.vpc_module.vpc_id
  environment = var.environment
}

# ELASTIC IP 
module "elastic_ip_module" {
  source      = "../../modules/elastic_ip"
  environment = var.environment
}


# # PUBLIC SUBNET
module "subnet_public_module" {
  source              = "../../modules/subnets/public"
  vpc_id              = module.vpc_module.vpc_id
  vpc_cidr_block      = module.vpc_module.vpc_cidr_block
  internet_gateway_id = module.internet_gateway_module.internet_gateway_id

  availability_zones   = var.availability_zones
  environment          = var.environment
  public_subnets_count = var.public_subnets_count
}

# # PRIVATE SUBNET
module "subnet_private_module" {
  source                = "../../modules/subnets/private"
  vpc_id                = module.vpc_module.vpc_id
  vpc_cidr_block        = module.vpc_module.vpc_cidr_block
  availability_zones    = var.availability_zones
  elastic_ip_id         = module.elastic_ip_module.elastic_ip_id
  environment           = var.environment
  private_subnets_count = var.private_subnets_count
  public_subnets        = module.subnet_public_module.public_subnets
}

module "security_groups_module" {
  source      = "../../modules/security_groups"
  vpc_id      = module.vpc_module.vpc_id
  environment = var.environment
}
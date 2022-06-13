provider "aws" {
  profile                  = var.aws_profile
  region                   = var.aws_region
  shared_credentials_files = [var.aws_credentials_file]
}


terraform {
  required_version = ">= 0.14.4"

  backend "s3" {
    bucket = "terraform-state-ceros-ski-caesar"
    key = "ceros-ski/production/compute/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform_lock"
    encrypt = true
  }
}

/******************************************************************************
* Bastion Host
*******************************************************************************/
/**/

module "security_groups_module" {
  source            = "../../modules/security_groups"
  vpc_id            = module.vpc_module.vpc_id
  environment = var.environment
}

module "bation_module" {
  source = "../../modules/bation"

  security_group_bation_id = 
  public_key = var.public_key
  public_subnets =
  environment = var.environment
}

module "iam_module" {
  source = "../../modules/iam"
}

module "load_balancer_module" {
  source = "../../modules/load_balancer"

  public_subnets = 
  security_group_load_balancer_id = 
  vpc_id = 
}

module "ecs_cluster_module" {
  source = "../../modules/ecs_cluster"

  load_balancer_target_group = module.load_balancer_module.load_balancer_target_group
  load_balancer_listener = module.load_balancer_module.load_balancer_listener

  security_group_autoscaling_id =
  private_subnets =
  repository_url = var.repository_url
  iam_instance_profile = module.iam_module.iam_instance_profile
}
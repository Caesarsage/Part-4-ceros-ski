provider "aws" {
  profile                  = var.aws_profile
  region                   = var.aws_region
  shared_credentials_files = [var.aws_credentials_file]
}


terraform {
  required_version = ">= 0.14.4"

  backend "s3" {
    bucket         = "terraform-state-ceros-ski-caesar"
    key            = "ceros-ski/production/compute/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform_lock"
    encrypt        = true
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Environment = var.environment
    Name        = "ceros-ski-production-main_vpc"
    Application = "ceros-ski"
    Resource    = "modules.environment.aws_vpc.main_vpc"
  }
}

data "aws_subnet_ids" "private_subnets" {
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Environment = var.environment
    Resource    = "modules.availability_zone.aws_subnet.private_subnet"
  }
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Resource    = "modules.availability_zone.aws_subnet.public_subnet"
    Environment = var.environment
    Application = "ceros-ski"
  }
}

data "aws_security_groups" "security_group_bastion" {
  tags = {
    Resource    = "modules.availability_zone.aws_security_group.bastion"
    Application = "ceros-ski"
    Environment = var.environment
  }
}

data "aws_security_groups" "security_group_autoscaling" {
  tags = {
    Application = "ceros-ski"
    Resource    = "modules.ecs.cluster.aws_security_group.autoscaling_group"
    Environment = var.environment
  }
}

data "aws_security_groups" "security_group_ecs-alb" {
  tags = {
    Application = "ceros-ski"
    Resource    = "modules.ecs.cluster.aws_security_group.ecs-alb-security-group"
    Environment = var.environment
  }
}

/******************************************************************************
* Bastion Host
*******************************************************************************/
/**/



module "bastion_module" {
  source = "../../modules/bastion"

  security_group_bastion_id = data.aws_security_groups.security_group_bastion.id
  public_key                = var.public_key
  public_subnets            = data.aws_subnet_ids.public_subnets
  environment               = var.environment
}

module "iam_module" {
  source = "../../modules/iam"
}

module "load_balancer_module" {
  source = "../../modules/load_balancer"

  public_subnets                  = data.aws_subnet_ids.public_subnets
  security_group_load_balancer_id = data.aws_security_groups.security_group_ecs-alb.id
  vpc_id                          = data.aws_vpc.vpc.id
}

module "ecs_cluster_module" {
  source = "../../modules/ecs_cluster"

  load_balancer_target_group = module.load_balancer_module.load_balancer_target_group
  load_balancer_listener     = module.load_balancer_module.load_balancer_listener

  security_group_autoscaling_id = data.aws_security_groups.security_group_autoscaling.id
  private_subnets               = data.aws_subnet_ids.private_subnets.id
  repository_url                = var.repository_url
  iam_instance_profile          = module.iam_module.iam_instance_profile
  environment                   = var.environment
}
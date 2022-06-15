data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-ceros-ski-caesar"
    key            = "ceros-ski/production/network/terraform.tfstate"
    region         = "us-east-1"
  }
}

module "security_groups_module" {
  source      = "../security_groups"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  environment = var.environment
}

module "bastion_module" {
  source = "../bastion"

  security_group_bastion_id = module.security_groups_module.security_group_bation_id
  public_key                = var.public_key
  public_subnets            = data.terraform_remote_state.network.outputs.public_subnets
  environment               = var.environment
}

module "iam_module" {
  source = "../iam"
}

module "load_balancer_module" {
  source = "../load_balancer"

  public_subnets                  = data.terraform_remote_state.network.outputs.public_subnets
  security_group_load_balancer_id = module.security_groups_module.security_group_load_balancer_id
  vpc_id                          = data.terraform_remote_state.network.outputs.vpc_id
}

module "ecs_cluster_module" {
  source = "../ecs_cluster"

  load_balancer_target_group = module.load_balancer_module.load_balancer_target_group
  load_balancer_listener     = module.load_balancer_module.load_balancer_listener

  security_group_autoscaling_id = module.security_groups_module.security_group_autoscaling_id
  private_subnets               = data.terraform_remote_state.network.outputs.private_subnets
  repository_url                = var.repository_url
  iam_instance_profile          = module.iam_module.iam_instance_profile
  environment                   = var.environment
}
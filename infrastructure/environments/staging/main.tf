# VPC
modue "vpc_module" {
  source   = "./modules/vpc"
}

# INTERNET GATEWAY
module "internet_gateway_module" {
  source   = "./modules/internet_gateway"
  vpc_id   = module.vpc_module.vpc_id
}

# ELASTIC IP 
module "elastic_ip_module" {
  source = "./modules/elastic_ip"
}

# PUBLIC SUBNET
module "subnet_public_module" {
  source            = "./modules/subnets/public"
  vpc_id            = module.vpc_module.vpc_id
  vpc_cidr_block = module.vpc_module.vpc_cidr_block
  internet_gateway_id = module.internet_gateway_module.internet_gateway_id
  elastic_ip_id = module.elastic_ip_module.elastic_ip_id
  availability_zone = var.availability_zone
  environment = var.environment
}

# PRIVATE SUBNET
module "subnet_private_module" {
  source            = "./modules/subnets/private"
  vpc_id            = module.vpc_module.vpc_id
  vpc_cidr_block = module.vpc_module.vpc_cidr_block
  availability_zone = var.availability_zone
  elastic_ip_id = module.elastic_ip_module.elastic_ip_id
  internet_gateway_id = module.internet_gateway_module.internet_gateway_id
  environment = var.environment
}

module "security_groups_module" {
  source            = "./modules/security_groups"
  vpc_id            = module.vpc_module.vpc_id
  environment = var.environment
}

/**
* The public key for the key pair we'll use to ssh into our bastion instance.
*/
resource "aws_key_pair" "bastion" {
  key_name   = "ceros-ski-bastion-key-us-east-1a"
  public_key = var.public_key
}

/**
* This parameter contains the AMI ID for the most recent Amazon Linux 2 ami,
* managed by AWS.
*/
data "aws_ssm_parameter" "linux2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn-ami-hvm-x86_64-ebs"
}

/**
* Launch a bastion instance we can use to gain access to the private subnets of
* this availabilty zone.
*/
resource "aws_instance" "bastion" {
  ami           = data.aws_ssm_parameter.linux2_ami.value
  key_name      = aws_key_pair.bastion.key_name
  instance_type = "t3.micro"

  associate_public_ip_address = true
  subnet_id                   = element(module.subnet_public_module.public_subnets, 0).id
  vpc_security_group_ids      = [module.security_groups_module.security_group_bation_id]

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Name        = "ceros-ski-${var.environment}-us-east-1a-bastion"
    Resource    = "modules.availability_zone.aws_instance.bastion"
  }
}


/******************************************************************************
* ECS Cluster
*
* Create ECS Cluster and its supporting services, in this case EC2 instances in
* and Autoscaling group.
*
* *****************************************************************************/

/**
* The ECS Cluster and its services and task groups. 
*
* The ECS Cluster has no dependencies, but will be referenced in the launch
* configuration, may as well define it first for clarity's sake.
*/

resource "aws_ecs_cluster" "cluster" {
  name = "ceros-ski-${var.environment}"

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Resource    = "modules.ecs.cluster.aws_ecs_cluster.cluster"
  }
}

/*******************************************************************************
* AutoScaling Group
*
* The autoscaling group that will generate the instances used by the ECS
* cluster.
*
********************************************************************************/

/**
* The IAM policy needed by the ecs agent to allow it to manage the instances
* that back the cluster.  This is the terraform structure that defines the
* policy.
*/
module iam_module {
  source ="./modules/iam"
}

/** 
* This parameter contains the AMI ID of the ECS Optimized version of Amazon
* Linux 2 maintained by AWS.  We'll use it to launch the instances that back
* our ECS cluster.
*/


data "aws_ssm_parameter" "cluster_ami_id" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

/**
* The launch configuration for the autoscaling group that backs our cluster.  
*/
resource "aws_launch_configuration" "cluster_laucher" {
  name                 = "ceros-ski-${var.environment}-cluster"
  image_id             = module.iam_module.data_image_id_value
  instance_type        = "t3.micro"
  iam_instance_profile = module.iam_module.iam_instance_profile_name
  security_groups      = [module.security_groups_module.security_group_autoscaling_id]

  // Register our EC2 instances with the correct ECS cluster.
  user_data = <<EOF
#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.cluster.name}" >> /etc/ecs/ecs.config
EOF
}

/**
* The autoscaling group that backs our ECS cluster.
*/
resource "aws_autoscaling_group" "cluster" {
  name     = "ceros-ski-${var.environment}-cluster"
  min_size = 1
  max_size = 2

  vpc_zone_identifier  = [for subnet in module.subnet_private_module.private_subnets : subnet.id]
  launch_configuration = aws_launch_configuration.cluster_laucher.name

  tags = [{
    "key"                 = "Application"
    "value"               = "ceros-ski"
    "propagate_at_launch" = true
    },
    {
      "key"                 = "Environment"
      "value"               = var.environment
      "propagate_at_launch" = true
    },
    {
      "key"                 = "Resource"
      "value"               = "modules.ecs.cluster.aws_autoscaling_group.cluster"
      "propagate_at_launch" = true
  }]
}

/**
* Create the task definition for the ceros-ski backend, in this case a thin
* wrapper around the container definition.
*/
resource "aws_ecs_task_definition" "backend" {
  family       = "ceros-ski-${var.environment}-backend"
  network_mode = "awsvpc"

  container_definitions = <<EOF
[
  {
    "name": "ceros-ski",
    "image": "${var.repository_url}:latest",
    "environment": [
      {
        "name": "PORT",
        "value": "80"
      }
    ],
    "cpu": 512,
    "memoryReservation": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ]
  }
]
EOF

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Name        = "ceros-ski-${var.environment}-backend"
    Resource    = "modules.environment.aws_ecs_task_definition.backend"
  }
}

/**
* Create the ECS Service that will wrap the task definition.  Used primarily to
* define the connections to the load balancer and the placement strategies and
* constraints on the tasks.
*/
resource "aws_ecs_service" "backend" {
  name            = "ceros-ski-${var.environment}-backend"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.backend.arn

  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  network_configuration {
    security_groups = [aws_security_group.autoscaling_group.id]
    subnets         = aws_subnet.private_subnets.*.id
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ceros-ski.id
    container_name   = "ceros-ski"
    container_port   = 80
  }
  depends_on = [
    aws_lb_listener.ceros-ski
  ]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Resource    = "modules.environment.aws_ecs_service.backend"
  }}
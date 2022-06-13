
resource "aws_ecs_cluster" "cluster" {
  name = "ceros-ski-${var.environment}"

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Resource    = "modules.ecs.cluster.aws_ecs_cluster.cluster"
  }
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
  image_id             = data.aws_ssm_parameter.cluster_ami_id.value
  instance_type        = "t3.micro"
  iam_instance_profile = var.iam_instance_profile
  security_groups      = [var.security_group_autoscaling_id]

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

  vpc_zone_identifier  = [for subnet in var.private_subnets : subnet.id]
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
    security_groups = [var.security_group_autoscaling_id]
    subnets         = var.private_subnets.*.id
  }
  load_balancer {
    target_group_arn = var.load_balancer_target_group
    container_name   = "ceros-ski"
    container_port   = 80
  }
  depends_on = [
    var.load_balancer_listener
  ]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Resource    = "modules.environment.aws_ecs_service.backend"
  }
}
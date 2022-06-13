/**
*Load Balancer to be attached to the ECS cluster to distribute the load among instances
*/
resource "aws_lb" "default" {
  name            = "ecs-lb"
  subnets         = var.public_subnets.*.id
  security_groups = [var.security_group_load_balancer_id]
}

resource "aws_lb_target_group" "ceros-ski" {
  name        = "ceros-ski-target"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "ceros-ski" {
  load_balancer_arn = aws_lb.default.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.ceros-ski.id
    type             = "forward"
  }
}
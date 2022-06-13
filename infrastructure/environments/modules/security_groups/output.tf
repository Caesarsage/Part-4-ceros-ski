output "security_group_bation_id" {
  value =  aws_security_group.bastion.id
}

output "security_group_autoscaling_id" {
  value = aws_security_group.autoscaling_group.id
}

output "security_group_load_balancer_id" {
  value = aws_security_group.lb.id
}
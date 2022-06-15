output "load_balancer_target_group" {
  value = aws_lb_target_group.ceros-ski.id
}
output "load_balancer_listener" {
  value = aws_lb_listener.ceros-ski
}
output "load-balancer-ip" {
  value = aws_lb.default.dns_name
}
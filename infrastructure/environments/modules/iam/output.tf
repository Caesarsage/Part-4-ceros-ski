output "data_image_id_value" {
  value = data.aws_ssm_parameter.cluster_ami_id.value
}

output "iam_instance_profile" {
  value = aws_iam_instance_profile.ecs_agent.name
}
output "data_image_id_value" {
  value = data.aws_ssm_parameter.cluster_ami_id.value
}
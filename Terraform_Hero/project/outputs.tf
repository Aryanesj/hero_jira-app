#==============================| Outputs |====================================
output "password_rds" {
  value = nonsensitive(data.aws_ssm_parameter.my_rds_password.value)
}

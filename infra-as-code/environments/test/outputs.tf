output "password" {
  value     = values(aws_iam_user_login_profile.user_login).*.password
  sensitive = true
}
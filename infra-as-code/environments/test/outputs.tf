# output "password" {
#   value     = values(aws_iam_user_login_profile.user_login).*.password
#   sensitive = true
# }

output "dns_entry_url" {
  value     = "http://${aws_lb.front_end.dns_name}"
}
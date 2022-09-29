# output "password" {
#   value     = values(aws_iam_user_login_profile.user_login).*.password
#   sensitive = true
# }

output "MAIN_ENTRY_WEB" {
  value     = "http://${aws_lb.front_end.dns_name}"
}

output "FRONT_PLACEHOLDER_URL_REGISTRY" {
  value     = aws_ecr_repository.docker_repo_frontend.repository_url
}

output "BACK_PLACEHOLDER_URL_REGISTRY" {
  value     = aws_ecr_repository.docker_repo_backend.repository_url
}

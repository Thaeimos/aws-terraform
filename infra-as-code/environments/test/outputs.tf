# output "password" {
#   value     = values(aws_iam_user_login_profile.user_login).*.password
#   sensitive = true
# }

output "MAIN_ENTRY_WEB" {
  value     = "http://${aws_lb.front_end.dns_name}"
}

output "ECR_REPOSITORY_FRONT" {
  value     = aws_ecr_repository.docker_repo_frontend.name
}

output "ECS_CLUSTER_FRONT" {
  value     = aws_ecs_cluster.ecs_cluster_frontend.name
}

# output "ECS_SERVICE_FRONT" {
#   value     = ""
# }

output "MAIN_ENTRY_WEB" {
  value = "http://${aws_lb.front_end.dns_name}"
}

output "FRONT_NAME" {
  value = aws_iam_role.ecs_agent_front.name
}

output "FRONT_REG_URL" {
  value = aws_ecr_repository.docker_repo_frontend.repository_url
}

output "BACK_NAME" {
  value = aws_ecr_repository.docker_repo_backend.name
}

output "BACK_REG_URL" {
  value = aws_ecr_repository.docker_repo_backend.repository_url
}

output "BACK_LB_DNS" {
  value = aws_lb.back_end.dns_name
}

output "FRONT_EXEC_ROLE_TASK" {
  value = aws_ecs_task_definition.front_task_definition.execution_role_arn
}

output "BACK_EXEC_ROLE_TASK" {
  value = aws_ecs_task_definition.back_task_definition.execution_role_arn
}

output "BACK_DB_SECRET_GROUP" {
  value = aws_secretsmanager_secret.secretmasterDB.arn
}

output "XRAY_REG_URL" {
  value       = aws_ecr_repository.docker_repo_backend_xray.repository_url
  description = "The URL for the XRAY image for private subnets."
}
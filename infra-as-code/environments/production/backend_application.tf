

#####################################################################
# Backend application
#####################################################################

# Security groups
resource "aws_security_group" "alb_application_tier" {
  name        = "allow_connection_to_alb_application_tier"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "HTTP from anywhere"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.presentation_tier.id]
  }

  ingress {
    description     = "HTTP from anywhere"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.presentation_tier.id]
  }

  tags = {
    Name = "alb_application_tier_sg"
  }
}

resource "aws_security_group" "ecs_task_back" {
  name   = "Backend fargate tasks SG"
  vpc_id = aws_vpc.vpc.id

  ingress {
    protocol         = "tcp"
    from_port        = 3000
    to_port          = 3000
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "Backend fargate tasks SG"
    Environment = var.environment
  }
}

# Load Balancer
resource "aws_lb" "back_end" {
  name               = "${var.name}-back-end-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_presentation_tier.id]
  subnets            = values(aws_subnet.priv_subnet)[*].id

  enable_deletion_protection = false
}

resource "aws_lb_listener" "back_end" {
  load_balancer_arn = aws_lb.back_end.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.back_end.arn
  }
}

resource "aws_lb_target_group" "back_end" {
  name        = "back-end-lb-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    matcher = "200,301,302"
    path    = "/healthcheck"
  }
}

# IAM for ECS
data "aws_iam_policy_document" "ecs_agent_back" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "fargate_execution" {
  name   = "fargate_execution_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "ssm:GetParameters",
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
      ],
      "Resource": [
          "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
          "xray:GetSamplingStatisticSummaries"
      ],
      "Resource": [
          "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "fargate_execution" {
  name               = "back-fargate-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent_back.json
}

resource "aws_iam_role" "fargate_task" {
  name               = "back-fargate-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent_back.json
}

resource "aws_iam_policy" "fargate_task" {
  name   = "fargate_task_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "servicediscovery:ListServices",
            "servicediscovery:ListInstances"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "fargate-execution" {
  role       = aws_iam_role.fargate_execution.name
  policy_arn = aws_iam_policy.fargate_execution.arn
}

resource "aws_iam_role_policy_attachment" "fargate-task" {
  role       = aws_iam_role.fargate_task.name
  policy_arn = aws_iam_policy.fargate_task.arn
}

# ECR
resource "aws_ecr_repository" "docker_repo_backend" {
  name = var.backend_name
}

resource "aws_ecr_lifecycle_policy" "docker_repo_backend" {
  repository = aws_ecr_repository.docker_repo_backend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })
}

# XRAY for private subnet
resource "aws_ecr_repository" "docker_repo_backend_xray" {
  name = "${var.backend_name}-xray"
}

resource "aws_ecr_lifecycle_policy" "docker_repo_backend_xray" {
  repository = aws_ecr_repository.docker_repo_backend_xray.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })
}

# ECS
resource "aws_ecs_cluster" "ecs_cluster_backend" {
  name = var.backend_name
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.ecs_cluster_backend.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# Cloudwatch log group
resource "aws_cloudwatch_log_group" "log_ecs_backend" {
  name              = var.backend_name
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Application = var.backend_name
  }
}

# Placeholder task and service for backend
data "template_file" "back_task_definition_template" {
  template = file("task_definition.json.tpl")
  vars = {
    REPOSITORY_URL = replace(aws_ecr_repository.docker_repo_backend.repository_url, "https://", "")
    ENV_VAR        = var.environment
    CONTAINER_NAME = var.backend_name
  }
}

resource "aws_ecs_task_definition" "back_task_definition" {
  family                   = var.backend_name
  container_definitions    = data.template_file.back_task_definition_template.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256" # Need CPU and memory at the task level, not container level
  memory                   = "512"
  execution_role_arn       = aws_iam_role.fargate_execution.arn
  task_role_arn            = aws_iam_role.fargate_task.arn
}

resource "aws_ecs_service" "backend_application" {
  name            = var.backend_name
  cluster         = aws_ecs_cluster.ecs_cluster_backend.id
  task_definition = aws_ecs_task_definition.back_task_definition.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.back_end.arn
    container_name   = var.backend_name
    container_port   = 3000
  }

  network_configuration {
    subnets         = values(aws_subnet.priv_subnet)[*].id
    security_groups = [aws_security_group.ecs_task_back.id]
  }

  lifecycle {
    ignore_changes = [task_definition, deployment_minimum_healthy_percent]
  }
}

# Auto scaling
resource "aws_appautoscaling_target" "ecs_back" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster_backend.name}/${aws_ecs_service.backend_application.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_back.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_back.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_back.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 80
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_back.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_back.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_back.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 60
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
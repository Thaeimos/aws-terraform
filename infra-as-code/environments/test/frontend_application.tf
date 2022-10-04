#####################################################################
# Frontend application
#####################################################################

# Security groups
resource "aws_security_group" "alb_presentation_tier" {
  name        = "allow_connection_to_alb_presentation_tier"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description     = "Outgoing connections to anywhere"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_presentation_tier_sg"
  }
}

resource "aws_security_group" "presentation_tier" {
  name        = "allow_connection_to_presentation_tier"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "HTTP from anywhere"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_presentation_tier.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "presentation_tier_sg"
  }
}

# IAM for ECS
data "aws_iam_policy_document" "ecs_agent_front" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent_front" {
  name               = var.frontend_name
  assume_role_policy = data.aws_iam_policy_document.ecs_agent_front.json
}

resource "aws_iam_role_policy_attachment" "ecs_agent_front" {
  role       = aws_iam_role.ecs_agent_front.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent_front" {
  name = var.frontend_name
  role = aws_iam_role.ecs_agent_front.name
}

# Dynamic AMI
data "aws_ami" "ecs_ami" {
  most_recent   = true
  owners        = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ECR
resource "aws_ecr_repository" "docker_repo_frontend" {
  name  = var.frontend_name
}

resource "aws_ecr_lifecycle_policy" "docker_repo_frontend" {
  repository = aws_ecr_repository.docker_repo_frontend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      action       = {
        type = "expire"
      }
      selection     = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })
}

# ECS
resource "aws_ecs_cluster" "ecs_cluster_frontend" {
  name  = var.frontend_name
}

# Cloudwatch log group
resource "aws_cloudwatch_log_group" "log_ecs_frontend" {
  name                = var.frontend_name
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    Application = var.frontend_name
  }
}

# Placeholder task and service for frontend
data "template_file" "front_task_definition_template" {
  template = file("task_definition.json.tpl")
  vars = {
    REPOSITORY_URL = replace(aws_ecr_repository.docker_repo_frontend.repository_url, "https://", "")
    ENV_VAR = var.environment
    CONTAINER_NAME = var.frontend_name
  }
}

resource "aws_ecs_task_definition" "front_task_definition" {
  family                    = var.frontend_name
  container_definitions     = data.template_file.front_task_definition_template.rendered
  requires_compatibilities  = ["EC2"]
  execution_role_arn        = aws_iam_role.fargate_execution.arn
}

resource "aws_ecs_service" "frontend_application" {
  name                  = var.frontend_name
  cluster               = aws_ecs_cluster.ecs_cluster_frontend.id
  task_definition       = aws_ecs_task_definition.front_task_definition.arn
  desired_count         = 3

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 100
    base              = 0
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.front_end.arn
    container_name   = var.frontend_name
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count, deployment_minimum_healthy_percent]
  }
}

# Autoscaling group
resource "aws_launch_configuration" "ecs_launch_config" {
  name_prefix           = "${var.name}-"
  image_id              = data.aws_ami.ecs_ami.id
  iam_instance_profile  = aws_iam_instance_profile.ecs_agent_front.name
  security_groups       = [aws_security_group.presentation_tier.id]
  user_data             = templatefile("user-data.sh.tpl", { cluster_name = "${aws_ecs_cluster.ecs_cluster_frontend.name}" })

  instance_type         = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    encrypted = true
  }
}

resource "aws_autoscaling_group" "public_ecs_asg" {
  name                      = "asg"
  vpc_zone_identifier       = values(aws_subnet.pub_subnet)[*].id
  launch_configuration      = aws_launch_configuration.ecs_launch_config.name

  desired_capacity          = 3
  min_size                  = 1
  max_size                  = 20
  health_check_grace_period = 90
  health_check_type         = "EC2"

  instance_refresh {
    strategy = "Rolling"
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  warm_pool {
    pool_state                  = "Hibernated"
    min_size                    = 3
    max_group_prepared_capacity = 10

  }
}

resource "aws_ecs_capacity_provider" "ec2" {
  name = "ec2"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.public_ecs_asg.arn
    managed_scaling {
      target_capacity           = 100
      instance_warmup_period    = 30
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = aws_autoscaling_group.public_ecs_asg.max_size
      status                    = "ENABLED"
    }
    managed_termination_protection = "DISABLED"
  }
}

resource "aws_ecs_cluster_capacity_providers" "front_provider" {
  cluster_name = aws_ecs_cluster.ecs_cluster_frontend.name
  capacity_providers = [
    aws_ecs_capacity_provider.ec2.name
  ]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 100
    base              = 0
  }
}

resource "aws_appautoscaling_target" "ecs" {
  min_capacity       = 4
  max_capacity       = 20
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster_frontend.name}/${aws_ecs_service.frontend_application.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "ecs-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70
    scale_in_cooldown  = 0
    scale_out_cooldown = 0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_iam_policy" "ec2_execution" {
  name   = "ec2_execution_policy"
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
    }
  ]
}
EOF
}

resource "aws_iam_role" "ec2_execution" {
  name               = "front-ec2-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent_back.json
}

resource "aws_iam_role_policy_attachment" "ec2-execution" {
  role       = aws_iam_role.ec2_execution.name
  policy_arn = aws_iam_policy.ec2_execution.arn
}
terraform {
  required_version = "~> 1.1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.31.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }
}

# The backend config variables come from a backend.auto.tfvars file
terraform {
  backend "s3" {
  }
}

provider "aws" {
  region  = var.region

  default_tags {
    tags = {
      purpose       = var.name
      environment   = var.environment
    }
  }
}

# VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.main_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC01"
  }
}

# Internet gateway and public route
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.name
  }
}

# Dynamic AZs and subnets
data "aws_availability_zones" "azs" {
  state = "available"
}

locals {
  az_names = data.aws_availability_zones.azs.names
}

resource "aws_subnet" "pub_subnet" {
  for_each                = {for idx, az_name in local.az_names: idx => az_name}
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.main_cidr_block, 8, each.key)
  availability_zone       = local.az_names[each.key]
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_${local.az_names[each.key]}"
  }
}

resource "aws_subnet" "priv_subnet" {
  for_each                = {for idx, az_name in local.az_names: idx => az_name}
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.main_cidr_block, 8, each.key + length(local.az_names))
  availability_zone       = local.az_names[each.key]
  map_public_ip_on_launch = true

  tags = {
    Name = "private_subnet_${local.az_names[each.key]}"
  }
}

# Public routes
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "public-route-${var.name}"
  }
}

resource "aws_route_table_association" "route_table_association" {
  for_each       = {for idx, az_name in local.az_names: idx => az_name}
  subnet_id      = aws_subnet.pub_subnet[each.key].id
  route_table_id = aws_route_table.public.id
}

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
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_presentation_tier.id]
  }

  ingress {
    description     = "HTTP from anywhere"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_presentation_tier.id]
  }

  ingress {
    description     = "SSH from anywhere"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
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

# Endpoint and Load Balancer
resource "aws_lb" "front_end" {
  name               = "${var.name}-front-end-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_presentation_tier.id]
  subnets            = values(aws_subnet.pub_subnet)[*].id

  enable_deletion_protection = false
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}

resource "aws_lb_target_group" "front_end" {
  name     = "front-end-lb-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

# Autoscaling group
resource "aws_launch_configuration" "ecs_launch_config" {
  name_prefix           = "${var.name}-"
  image_id              = data.aws_ami.ecs_ami.id
  iam_instance_profile  = aws_iam_instance_profile.ecs_agent.name
  security_groups       = [aws_security_group.presentation_tier.id]
  user_data             = file("user-data.sh")
  instance_type         = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "public_ecs_asg" {
  name                      = "asg"
  vpc_zone_identifier       = values(aws_subnet.pub_subnet)[*].id
  launch_configuration      = aws_launch_configuration.ecs_launch_config.name

  desired_capacity          = 3
  min_size                  = 1
  max_size                  = 10
  health_check_grace_period = 300
  health_check_type         = "EC2"
}

# Frontend ECS
# IAM for ECS
data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}


resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent"
  role = aws_iam_role.ecs_agent.name
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
  name  = "${var.name}-ecs-frontend"
}

# ECS
resource "aws_ecs_cluster" "ecs_cluster_frontend" {
  name  = "${var.name}-ecs-cluster-frontend"
}

# data "template_file" "task_definition_template" {
#   template = file("task_definition.json.tpl")
#   vars = {
#     REPOSITORY_URL = replace(aws_ecr_repository.docker_repo_frontend.repository_url, "https://", "")
#   }
# }

# resource "aws_ecs_task_definition" "task_definition" {
#   family                = "worker"
#   container_definitions = data.template_file.task_definition_template.rendered
# }

# resource "aws_ecs_service" "worker" {
#   name            = "worker"
#   cluster         = aws_ecs_cluster.ecs_cluster_frontend.id
#   task_definition = aws_ecs_task_definition.task_definition.arn
#   desired_count   = 2
# }

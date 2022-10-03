#####################################################################
# VPC
#####################################################################

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
  map_public_ip_on_launch = false

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

# Elastic IPs and NAT Gateways
resource "aws_eip" "nat_ip" {
  for_each    = {for idx, az_name in local.az_names: idx => az_name}
  depends_on  = [aws_internet_gateway.internet_gateway]
  vpc         = true

  tags = {
    Name        = "EIP-${each.value}"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  for_each      = {for idx, az_name in local.az_names: idx => az_name}
  allocation_id = aws_eip.nat_ip[each.key].id
  subnet_id     = aws_subnet.pub_subnet[each.key].id
  depends_on    = [aws_internet_gateway.internet_gateway]

  tags = {
    Name        = "NAT-${each.value}"
  }
}

# Private routes
resource "aws_route_table" "private" {
  for_each  = {for idx, az_name in local.az_names: idx => az_name}
  vpc_id    = aws_vpc.vpc.id

  # route {
  #     cidr_block = "0.0.0.0/0"
  #     nat_gateway_id = aws_nat_gateway.nat_gateway[each.key].id
  # }

  tags = {
    Name = "private-route-${each.value}"
  }
}

resource "aws_route_table_association" "route_table_association_priv" {
  for_each       = {for idx, az_name in local.az_names: idx => az_name}
  subnet_id      = aws_subnet.priv_subnet[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}


#####################################################################
# External endpoint
#####################################################################

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

  health_check {
    matcher   = "200,301,302"
    path      = "/healthcheck"
  }
}

# VPC internal endpoints for Fargate
resource "aws_security_group" "vpc_endpoint" {
  name   = "vpc_endpoint_sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region}.s3" # ???
  vpc_endpoint_type = "Gateway"
  route_table_ids   = values(aws_route_table.private)[*].id

  tags = {
    Name        = "s3-endpoint"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "dkr" {
  vpc_id              = aws_vpc.vpc.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]
  subnet_ids = values(aws_subnet.priv_subnet)[*].id

  tags = {
    Name        = "dkr-endpoint"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "dkr_api" {
  vpc_id              = aws_vpc.vpc.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]
  subnet_ids = values(aws_subnet.priv_subnet)[*].id

  tags = {
    Name        = "dkr-api-endpoint"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.vpc.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]
  subnet_ids = values(aws_subnet.priv_subnet)[*].id

  tags = {
    Name        = "logs-endpoint"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = values(aws_subnet.priv_subnet)[*].id
	security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]
}


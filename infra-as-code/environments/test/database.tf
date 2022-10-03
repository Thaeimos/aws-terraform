
#####################################################################
# Database stack
#####################################################################

# RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnets"
  subnet_ids = values(aws_subnet.priv_subnet)[*].id

  tags = {
    Name = var.name
  }
}

# Security group
resource "aws_security_group" "rds_sg" {
  name        = "RDSSG"
  description = "Allows application tier to access the RDS instance"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "EC2 to MYSQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_task_back.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_sg"
  }
}

resource "aws_db_parameter_group" "rds_param" {
  name   = var.name
  family = "mysql8.0"

  parameter {
    name  = "max_allowed_packet"
    value = "16777216"
  }
}

resource "aws_db_instance" "rds_demo" {
  identifier                = var.name
  instance_class            = "db.t3.micro"
  allocated_storage         = 5 # We should use 100 for more IOPs but this is a demo...
  engine                    = "mysql"
  engine_version            = "8.0.28"
  username                  = var.db_username
  password                  = var.db_password
  db_subnet_group_name      = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.rds_sg.id]
  parameter_group_name      = aws_db_parameter_group.rds_param.name
  publicly_accessible       = false
  skip_final_snapshot       = true
  db_name                   = "mydatabase"
  multi_az                  = "true"
  storage_type              = "gp2"
  backup_retention_period   = 6
  final_snapshot_identifier = "mysql-final-snapshot"
  tags = {
    Name = "mysql-instance"
  }
}
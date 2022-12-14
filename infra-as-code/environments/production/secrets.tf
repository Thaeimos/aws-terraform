# Firstly create a random generated password to use in secrets.
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# Creating a AWS secret
resource "aws_secretsmanager_secret" "secretmasterDB" {
  name = "db-credentials"

  # lifecycle {
  #   prevent_destroy = true
  # }
}

# Creating a AWS secret versions
resource "aws_secretsmanager_secret_version" "sversion" {
  secret_id     = aws_secretsmanager_secret.secretmasterDB.id
  secret_string = <<EOF
   {
    "username": "${var.db_username}",
    "password_random": "${random_password.password.result}",
    "password": "${var.db_password}",
    "hostname": "${aws_db_instance.rds_demo.address}",
    "port": "${aws_db_instance.rds_demo.port}",
    "database": "${aws_db_instance.rds_demo.db_name}"
   }
EOF
}

# Importing the AWS secrets
data "aws_secretsmanager_secret" "secretmasterDB" {
  arn = aws_secretsmanager_secret.secretmasterDB.arn
}

# Importing the AWS secret version created previously using arn.
data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = data.aws_secretsmanager_secret.secretmasterDB.arn

  depends_on = [aws_secretsmanager_secret_version.sversion]
}

# # Cannot due to circular dependency
# # After importing the secrets storing into Locals
# locals {
#   db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)
# }
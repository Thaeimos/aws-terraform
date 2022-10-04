# Users creation
resource "aws_iam_group" "read_only" {
  name = "read-only-users"
  path = "/"

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy" "read_only_access" {
  name = "ReadOnlyAccess"
}

resource "aws_iam_group_policy_attachment" "read_only" {
  group      = aws_iam_group.read_only.name
  policy_arn = data.aws_iam_policy.read_only_access.arn

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_user" "user" {
  for_each      = toset(var.read_only_users)
  name          = each.value
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_user_group_membership" "devstream" {
  for_each = toset(var.read_only_users)
  user     = aws_iam_user.user[each.key].name
  groups   = [aws_iam_group.read_only.name]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_user_login_profile" "user_login" {
  for_each                = toset(var.read_only_users)
  user                    = aws_iam_user.user[each.key].name
  password_reset_required = true
}

# Set password policy for the whole account
resource "aws_iam_account_password_policy" "medium" {
  minimum_password_length        = 10
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = false
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 3

  lifecycle {
    prevent_destroy = true
  }
}
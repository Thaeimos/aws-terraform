# Users creation
resource "aws_iam_group" "read_only" {
  name = "read-only-users"
  path = "/"
}

data "aws_iam_policy" "read_only_access" {
  name = "ReadOnlyAccess"
}

resource "aws_iam_group_policy_attachment" "read_only" {
  group      = aws_iam_group.read_only.name
  policy_arn = data.aws_iam_policy.read_only_access.arn
}

resource "aws_iam_user" "user" {
  for_each      = toset(var.read_only_users)
  name          = each.value
  force_destroy = true
}

resource "aws_iam_user_group_membership" "devstream" {
  for_each    = toset(var.read_only_users)
  user        = "${aws_iam_user.user[each.key].name}"
  groups      = [aws_iam_group.read_only.name]
}

resource "aws_iam_user_login_profile" "user_login" {
  for_each                = toset(var.read_only_users)
  user                    = "${aws_iam_user.user[each.key].name}"
  password_reset_required = true
}
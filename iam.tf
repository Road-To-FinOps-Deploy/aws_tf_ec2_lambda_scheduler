resource "aws_iam_role" "iam_role_for_ec2_start_stop" {
  count              = var.enabled
  name               = "${var.function_prefix}scheduler_iam_role_ec2_start_stop"
  assume_role_policy = file("${path.module}/policies/LambdaAssume.pol")
}

resource "aws_iam_role_policy" "iam_role_policy_for_ec2_start_stop" {
  count  = var.enabled
  name   = "ExecuteLambda"
  role   = aws_iam_role.iam_role_for_ec2_start_stop[0].id
  policy = file("${path.module}/policies/LambdaExecution.pol")
}


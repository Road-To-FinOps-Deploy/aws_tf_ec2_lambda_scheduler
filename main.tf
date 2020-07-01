#Generating the zip files
data "archive_file" "ec2_scheduler_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/ec2_scheduler.py"
  output_path = "${path.module}/output/ec2_scheduler.zip"
}

resource "aws_lambda_function" "ec2_start" {
  count            = var.enabled
  filename         = "${path.module}/output/ec2_scheduler.zip"
  function_name    = "${var.function_prefix}scheduler_ec2_start"
  role             = aws_iam_role.iam_role_for_ec2_start_stop[0].arn
  handler          = "ec2_scheduler.start_lambda_handler"
  source_code_hash = data.archive_file.ec2_scheduler_zip.output_base64sha256
  runtime          = "python3.7"
  memory_size      = "512"
  timeout          = "150"
  environment {
      variables = { 
        REGION = var.aws_region
      }
    }
}

resource "aws_lambda_function" "ec2_stop" {
  count            = var.enabled
  filename         = "${path.module}/output/ec2_scheduler.zip"
  function_name    = "${var.function_prefix}scheduler_ec2_stop"
  role             = aws_iam_role.iam_role_for_ec2_start_stop[0].arn
  handler          = "ec2_scheduler.stop_lambda_handler"
  source_code_hash = data.archive_file.ec2_scheduler_zip.output_base64sha256
  runtime          = "python3.7"
  memory_size      = "512"
  timeout          = "150"
  environment {
      variables = { 
        REGION = var.aws_region
      }
    }
}

resource "aws_lambda_permission" "allow_cloudwatch_ec2_start" {
  count         = var.enabled
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_start[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_start_cloudwatch_rule[0].arn

  depends_on = [aws_lambda_function.ec2_start]
}

resource "aws_lambda_permission" "allow_cloudwatch_ec2_stop" {
  count         = var.enabled
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_stop[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_stop_cloudwatch_rule[0].arn

  depends_on = [aws_lambda_function.ec2_stop]
}

resource "aws_cloudwatch_event_rule" "ec2_start_cloudwatch_rule" {
  count               = var.enabled
  name                = "${var.function_prefix}scheduler_ec2_start_lambda_trigger"
  schedule_expression = var.ec2_start_cron
}

resource "aws_cloudwatch_event_target" "ec2_start_lambda" {
  count     = var.enabled
  rule      = aws_cloudwatch_event_rule.ec2_start_cloudwatch_rule[0].name
  target_id = "lambda_target"
  arn       = aws_lambda_function.ec2_start[0].arn
}

resource "aws_cloudwatch_event_rule" "ec2_stop_cloudwatch_rule" {
  count               = var.enabled
  name                = "${var.function_prefix}scheduler_ec2_stop_lambda_trigger"
  schedule_expression = var.ec2_stop_cron
}

resource "aws_cloudwatch_event_target" "ec2_stop_lambda" {
  count     = var.enabled
  rule      = aws_cloudwatch_event_rule.ec2_stop_cloudwatch_rule[0].name
  target_id = "lambda_target"
  arn       = aws_lambda_function.ec2_stop[0].arn
}


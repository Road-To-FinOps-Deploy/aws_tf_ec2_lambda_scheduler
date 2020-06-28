variable "aws_region" {
  default = "eu-west-1"
}

variable "ec2_start_cron" {
  description = "Rate expression for when to run the start ec2 lambda"
  default     = "cron(0 7 ? * MON-FRI *)"
}

variable "ec2_stop_cron" {
  description = "Rate expression for when to run the stop ec2 lambda"
  default     = "cron(0 21 ? * MON-FRI *)"
}

variable "function_prefix" {
  description = "Prefix for the name of the lambda created"
  default     = ""
}

variable "enabled" {
  default     = 1
  description = "Enable that module or not"
}

locals {
  # module_relpath = ".${replace(path.module, path.root , "")}"
  module_relpath = ".${replace(path.module, path.cwd, "")}"
}


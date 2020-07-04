# Lambda Scheduler
```
The script schedules the start/stop of EC2 instances based on tag, whether they are standalone instances or instances within an autoscaling group.
```

## Requirements

This assumes you have set the "nightly" tag on the EC2/Autoscaling group to 'onoff' or to keep it off unless needed.
The lambda affects only instances in the same region than your terraform.

Remember this uses UTC Time

Requires the following tag:
```
extra_tags = [
    {
      key                 = "nightly"
      value               = "onoff"
      propagate_at_launch = true
    },
  ]
```


## Usage:

```
module "aws_scheduler" {
  source      = ""
}
```

## Optional Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region |  | string | `"eu-west-1"` | no |
| ec2\_start\_cron | Rate expression for when to run the start ec2 lambda | string | `"cron(0 7 ? * MON-FRI *)"` | no |
| ec2\_stop\_cron | Rate expression for when to run the stop ec2 lambda | string | `"cron(0 21 ? * MON-FRI *)"` | no |
| enabled | Enable that module or not | string | `"1"` | no |
| function\_prefix | Prefix for the name of the lambda created | string | `""` | no |

## Testing 

Configure your AWS credentials using one of the [supported methods for AWS CLI
   tools](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html), such as setting the
   `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables. If you're using the `~/.aws/config` file for profiles then export `AWS_SDK_LOAD_CONFIG` as "True".
1. Install [Terraform](https://www.terraform.io/) and make sure it's on your `PATH`.
1. Install [Golang](https://golang.org/) and make sure this code is checked out into your `GOPATH`.
cd test
go mod init github.com/sg/sch
go test -v -run TestTerraformAwsExample
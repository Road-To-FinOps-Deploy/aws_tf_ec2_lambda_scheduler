import boto3
import sys
import os
import logging

TAG_SCHEDULER = os.getenv("TAG", "nightly")
region = os.environ["REGION"]
# define connections
autosc = boto3.client("autoscaling")
ec2 = boto3.resource("ec2")
ec2_client = boto3.client("ec2", region_name=region)


def setup():
    logger = logging.getLogger()

    for h in logger.handlers:
        logger.removeHandler(h)
    h = logging.StreamHandler(sys.stdout)

    FORMAT = "%(asctime)-15s [%(filename)s:%(lineno)d] :%(levelname)8s: %(message)s"
    h.setFormatter(logging.Formatter(FORMAT))
    logger.addHandler(h)
    logger.setLevel(logging.INFO)

    # Suppress the more verbose modules
    logging.getLogger("__main__").setLevel(logging.DEBUG)
    logging.getLogger("botocore").setLevel(logging.WARN)


def get_scheduled_autoscalings():
    autoscalings = autosc.describe_auto_scaling_groups()["AutoScalingGroups"]
    nightly_autoscalings = [
        a
        for a in autoscalings
        if any(t["Key"] == TAG_SCHEDULER and t["Value"] == "onoff" for t in a["Tags"])
    ]
    return nightly_autoscalings


def get_scheduled_ec2(state):
    ec2_filters = [
        {"Name": "tag:%s" % TAG_SCHEDULER, "Values": ["onoff"]},
        {"Name": "instance-state-name", "Values": [state]},
    ]
    return [instance.id for instance in ec2.instances.filter(Filters=ec2_filters)]


def start_ec2(instance_ids):
    if len(instance_ids) > 0:
        logging.info("Starting instances %s", instance_ids)
        startec2 = ec2_client.start_instances(InstanceIds=instance_ids, DryRun=False)
        logging.info("Finished starting instances %s", instance_ids)
    else:
        logging.info("No instance to start")


def stop_ec2(instance_ids):
    if len(instance_ids) > 0:
        logging.info("Stopping instances %s", instance_ids)
        startec2 = ec2_client.stop_instances(InstanceIds=instance_ids, DryRun=False)
        logging.info("Finished stopping instances %s", instance_ids)
    else:
        logging.info("No instance to stop")


# resume processes: launch, terminate etc.
def start_scheduled_autoscaling():
    for nightly_autoscaling in get_scheduled_autoscalings():
        autosc.resume_processes(
            AutoScalingGroupName=nightly_autoscaling["AutoScalingGroupName"],
            ScalingProcesses=[
                "Launch",
                "Terminate",
                "HealthCheck",
                "ReplaceUnhealthy",
                "ScheduledActions",
                "AlarmNotification",
                "AZRebalance",
            ],
        )

        autoscaling_instance_ids = [i["InstanceId"] for i in nightly_autoscaling]
        start_ec2(autoscaling_instance_ids)


# suspend processes: launch, terminate etc.
def stop_scheduled_autoscaling():
    for nightly_autoscaling in get_scheduled_autoscalings():
        autosc.suspend_processes(
            AutoScalingGroupName=nightly_autoscaling["AutoScalingGroupName"],
            ScalingProcesses=[
                "Launch",
                "Terminate",
                "HealthCheck",
                "ReplaceUnhealthy",
                "ScheduledActions",
                "AlarmNotification",
                "AZRebalance",
            ],
        )
        autoscaling_instance_ids = [i["InstanceId"] for i in nightly_autoscaling]
        stop_ec2(autoscaling_instance_ids)


def start_scheduled_ec2():
    # Look to start ec2 instances marked
    start_ec2(get_scheduled_ec2(state="stopped"))


def stop_scheduled_ec2():
    # Look to stop ec2 instances marked
    stop_ec2(get_scheduled_ec2(state="running"))


def stop_lambda_handler(event, context):
    setup()
    stop_scheduled_autoscaling()
    stop_scheduled_ec2()


def start_lambda_handler(event, context):
    setup()

    start_scheduled_autoscaling()
    start_scheduled_ec2()

def handler(event, context):
    start_lambda_handler({}, {})
    stop_lambda_handler({}, {})

if __name__ == "__main__":
    start_lambda_handler({}, {})
    stop_lambda_handler({}, {})

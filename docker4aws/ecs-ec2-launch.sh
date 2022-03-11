ecs-cli compose \
  --project-name ec2-project service up \
  --cluster-config ec2-test-App

ecs-cli ps --cluster-config newapp

[shut down:]
ecs-cli compose down --cluster-config ec2-test-App
ecs-cli down --force --cluster-config ec2-test-App
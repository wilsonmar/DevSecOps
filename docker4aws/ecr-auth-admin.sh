aws ecr get-login --no-include-email --region us-east-1

aws ecr create-repository --repository-name newrepo

aws ecr describe-repositories

docker images

docker-compose.yml

version: '3'
services:
  apache:
    image: 297972716276.dkr.ecr.us-east-1.amazonaws.com/newrepo:latest
    ports:
      - "80:80"

ecs-params.yml

version: 1
task_definition:
  services:
    apache:
      cpu_shares: 100
      mem_limit: 524288000

ecs-cli configure \
  --cluster ec2cluster \
  --region us-east-1 \
  --default-launch-type EC2 \
  --config-name ec2cluster

ecs-cli configure profile \
  --access-key <your-access-key> \
  --secret-key <your-secret-key> \
  --profile-name ec2cluster


ecs-cli up \
  --capability-iam \
  --size 1 \
  --instance-type t3.medium \
  --cluster-config ec2cluster


ecs-cli compose \
  --project-name ec2cluster service up \
  --cluster-config ec2cluster

ecs-cli ps --cluster-config ec2cluster

ecs-cli compose \
  --project-name ec2cluster service down \
  --cluster-config ec2cluster

ecs-cli down --force --cluster-config ec2cluster
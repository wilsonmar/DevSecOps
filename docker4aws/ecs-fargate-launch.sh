ecs-cli compose \
  --project-name wpfargate service up \
  --create-log-groups \
  --cluster-config wpfargate \
  --cluster wpfargate

ecs-cli ps --cluster wpfargate

ecs-cli compose \
  --project-name wpfargate service down \
  --cluster-config wpfargate

ecs-cli down \
  --force \
  --cluster-config wpfargate
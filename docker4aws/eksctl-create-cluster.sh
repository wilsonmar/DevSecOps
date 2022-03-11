eksctl create cluster \
  --name wp-cluster \
  --version 1.12 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4 \
  --node-ami auto

kubectl create secret generic mysql-pass --from-literal=password=bigsecret
kubectl get secrets

curl https://raw.githubusercontent.com/kubernetes/website/master/content/en/examples/application/wordpress/mysql-deployment.yaml > mysql-deployment.yaml

curl https://raw.githubusercontent.com/kubernetes/website/master/content/en/examples/application/wordpress/wordpress-deployment.yaml > wordpress-deployment.yaml

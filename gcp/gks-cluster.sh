#!/bin/bash -e

# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/main/GCP/gks-cluster.sh)" -v -i

# https://google.qwiklabs.com/focuses/8586?parent=catalog
# Kubernetes Engine: Qwik Start

echo ">>> Task 1: Set a default compute zone"
gcloud config set compute/zone us-central1-a
   # Updated property [compute/zone].

CLUSTER-NAME="mycluster1"  # hard-coded here!
echo ">>> Task 2: Create a GKE cluster: $CLUSTER-NAME"
gcloud container clusters create "$CLUSTER-NAME"

echo ">>> Task 3: Get authentication credentials for the cluster"
gcloud container clusters get-credentials "$CLUSTER-NAME"
   # Fetching cluster endpoint and auth data.
   # kubeconfig entry generated for my-cluster.

echo ">>> Task 4.1: Deploy a pre-defined app from a Google Container Registry bucket to the cluster"
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0
   # deployment.apps/hello-server created

echo ">>> Task 4.2: Create a Kubernetes Service by exposing your application to external traffic"
kubectl expose deployment hello-server --type=LoadBalancer --port 8080
   # --port specifies the port that the container exposes.
   # type="LoadBalancer" creates a Compute Engine load balancer for your container.
   # service/hello-server exposed

echo ">>> Task 4.3: Inspect the hello-server Service"
kubectl get service
   # NAME              TYPE              CLUSTER-IP        EXTERNAL-IP      PORT(S)           AGE
   # hello-server      loadBalancer      10.39.244.36      35.202.234.26    8080:31991/TCP    65s
   # kubernetes        ClusterIP         10.39.240.1       <none>           433/TCP           5m13s

# Manually view the application from your web browser:
# open a new tab and enter the address, replacing [EXTERNAL IP] with the EXTERNAL-IP for hello-server.
# http://[EXTERNAL-IP]:8080

echo ">>> Task 5: Deleting the cluster"
gcloud container clusters delete "$CLUSTER-NAME"
# When prompted, type Y to confirm.

# Congratulations!

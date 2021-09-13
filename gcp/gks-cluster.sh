#!/bin/bash -e

# This automates https://google.qwiklabs.com/focuses/8586?parent=catalog
# Kubernetes Engine: Qwik Start GSP100 (30 minutes)
# a Lab within https://google.qwiklabs.com/quests/29

# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/main/gcp/gks-cluster.sh)"
# stored at https://github.com/wilsonmar/DevSecOps/blob/main/gcp/gks-cluster.sh

MY_ZONE="us-central1-a"
CLUSTER_NAME="mycluster1"  # hard-coded here!
MY_APP_NAME="hello-server"

echo ">>> Task 1: Set a default compute zone: $MY_ZONE"
gcloud config set compute/zone "$MY_ZONE"
   # Updated property [compute/zone].

echo ">>> Task 2: Create a GKE cluster: $CLUSTER_NAME"
gcloud container clusters create "$CLUSTER_NAME"
   # WARNING: Starting in January 2021, clusters will use the Regular release channel by default when `--cluster-version`, `--release-channel`, `--no-enable-autoupgrade`, and `--no-enable-autorepair` flags are not specified.
   # WARNING: Currently VPC-native is not the default mode during cluster creation. In the future, this will become the default mode and can be disabled using `--no-enable-ip-alias` flag. Use `--[no-]enable-ip-alias` flag to suppress this warning.
   # WARNING: Starting with version 1.18, clusters will have shielded GKE nodes by default.
   # WARNING: Your Pod address range (`--cluster-ipv4-cidr`) can accommodate at most 1008 node(s).
   # WARNING: Starting with version 1.19, newly created clusters and node-pools will have COS_CONTAINERD as the default node image when no image type is specified.
   # Creating cluster mycluster1 in us-central1-a...⠏
      # The above takes several minutes 

echo ">>> Task 3: Get authentication credentials for the cluster"
gcloud container clusters get-credentials "$CLUSTER_NAME"
   # Fetching cluster endpoint and auth data.
   # kubeconfig entry generated for my-cluster.

echo ">>> Task 4.1: Deploy pre-defined app $MY_APP_NAME from a Google Container Registry bucket to the cluster"
kubectl create deployment "$MY_APP_NAME" --image=gcr.io/google-samples/hello-app:1.0
   # deployment.apps/hello-server created

echo ">>> Task 4.2: Create a Kubernetes Service by exposing your application to external traffic"
kubectl expose deployment "$MY_APP_NAME" --type=LoadBalancer --port 8080
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
gcloud container clusters delete "$CLUSTER_NAME"
   # The following clusters will be deleted.
   # - [mycluster1] in [us-central1-a]
 
 # When prompted, type Y to confirm.
   # Deleting cluster mycluster1...⠧
   # Deleted [https://container.googleapis.com/v1/projects/qwiklabs-gcp-00-6fb32a14bd72/zones/us-central1-a/clusters/mycluster1].

echo ">>> Congratulations!"

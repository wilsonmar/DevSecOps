#!/bin/bash -e

# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/main/gcp/gks-orches.sh)"

# https://google.qwiklabs.com/focuses/557?parent=catalog
# Orchestrating the Cloud with Kubernetes (GSP021 75 minutes)

echo ">>> Get the sample code from Google"
gsutil cp -r gs://spls/gsp021/* .

# Change into the directory needed for this lab:
cd orchestrate-with-kubernetes/kubernetes

# List the files to see what you're working with:
ls
   # The sample has the following layout:
   # deployments/  /* Deployment manifests */
   # nginx/        /* nginx config files */
   # pods/         /* Pod manifests */
   # services/     /* Services manifests */
   # tls/          /* TLS certificates */
   # cleanup.sh    /* Cleanup script */


echo ">>> Quick Kubernetes Demo - use kubectl to create a single instance of the nginx container:"
kubectl create deployment nginx --image=nginx:1.10.0
   # Kubernetes has created a deployment -- more about deployments later, 
   # deployments keep the pods up and running even when the nodes they run on fail.

# In Kubernetes, all containers run in a pod. 
echo ">>> kubectl get pods command to view the running nginx container:"
kubectl get pods

# Once the nginx container has a Running status 
echo ">>> Expose it outside of Kubernetes using the kubectl expose command:"
kubectl expose deployment nginx --port 80 --type LoadBalancer

# Behind the scenes Kubernetes created an external Load Balancer with a public IP address 
# attached to it. Any client who hits that public IP address will be routed to the pods behind the service. In this case that would be the nginx pod.

echo ">>> kubectl get services now using the kubectl get services command:"
kubectl get services

# Note: It may take a few seconds before the ExternalIP field is populated for your service. 
# This is normal -- just re-run the kubectl get services command every few seconds until 
# the field populates.
MY_EXTERNAL_IP=$( kubectl get service/servicename -o jsonpath='{.spec.clusterIP}' )
# kubectl get svc <your-service> -o yaml | grep ip
# kubectl get svc <service-name> -o yaml | grep clusterIP
# kubectl describe svc <service-name> | grep IP

echo ">>> Add the External IP to this command to hit the Nginx container remotely:"
curl "http://$MY_EXTERNAL_IP:80"

exit

echo ">>> Create Pods"
cat pods/monolith.yaml

kubectl create -f pods/monolith.yaml

kubectl get pods

# get more information about the monolith pod:
kubectl describe pods monolith

echo ">>> Interacting with Pods"

echo ">>> Create a secure pod that can handle https traffic:"
cd ~/orchestrate-with-kubernetes/kubernetes

echo ">> Explore the monolith service configuration file:"
cat pods/secure-monolith.yaml

echo ">>> Create the secure-monolith pods and their configuration data:"
kubectl create secret generic tls-certs --from-file tls/
kubectl create configmap nginx-proxy-conf --from-file nginx/proxy.conf
kubectl create -f pods/secure-monolith.yaml

echo ">>> Expose the secure-monolith Pod externally.To do that, create a Kubernetes service:"
echo ">>> Explore the monolith service configuration file:"
cat services/monolith.yaml

echo ">>> create the monolith service from the monolith service configuration file:"
kubectl create -f services/monolith.yaml
    # service/monolith created

echo ">>>  allow traffic to the monolith service on the exposed nodeport:"
gcloud compute firewall-rules create allow-monolith-nodeport --allow=tcp:31000



echo ">>> Creating a Service"

echo ">>> Adding Labels to Pods"

echo ">>> Deploying Applications with Kubernetes"

echo ">>> Creating Deployments"



#!/bin/bash -e

# Within Google Cloud Shell:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/main/gcp/gks-deploy.sh)"

# https://google.qwiklabs.com/focuses/639?parent=catalog
# Managing Deployments Using Kubernetes Engine (GSP053, 60 minutes)

echo ">>> Get sample code for this lab for creating and running containers and deployments:"
gsutil -m cp -r gs://spls/gsp053/orchestrate-with-kubernetes .
cd orchestrate-with-kubernetes/kubernetes
pwd

echo ">>> Create a cluster with five n1-standard-1 nodes (this will take a few minutes to complete):"
gcloud container clusters create bootcamp --num-nodes 5 --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw"



echo ">>> kubectl explain deployment to Learn about the deployment object:"
kubectl explain deployment

echo ">>> See all of the fields, recursively:"
kubectl explain deployment --recursive

echo ">>> kubectl explain deployment.metadata.name "
kubectl explain deployment.metadata.name


echo ">>> Manually update the deployments/auth.yaml configuration file:"
vi deployments/auth.yaml
echo ">>> Change the image in the containers section of the Deployment :"
   # containers:
   # - name: auth
   #   image: "kelseyhightower/auth:1.0.0"

pause read
# In batch mode, copy in instead of changing manually:
exit


echo ">>> Create deployment object using kubectl create:"
kubectl create -f deployments/auth.yaml

echo ">>> Verify that it was created: kubectl get deployments"
kubectl get deployments

    # Once the deployment is created, Kubernetes will create a ReplicaSet for the Deployment. 
    # We can verify that a ReplicaSet was created for our Deployment:

echo ">>> kubectl get replicasets "
kubectl get replicasets

echo ">>> We should see a ReplicaSet with a name like auth-xxxxxxx"

echo ">>> view Pods created as part of Deployment: kubectl get pods"
kubectl get pods
   # The single Pod is created by the Kubernetes when the ReplicaSet is created.

echo ">>> Create a auth service for our auth deployment:"
   # You've already seen service manifest files, so we won't go into the details here. 
kubectl create -f services/auth.yaml

echo ">>> Create and expose the hello Deployment:"
kubectl create -f deployments/hello.yaml

echo ">>> Create and expose the hello Services:"
kubectl create -f services/hello.yaml

echo ">>> Create and expose the frontend Deployment:"
kubectl create configmap nginx-frontend-conf --from-file=nginx/frontend.conf
kubectl create -f deployments/frontend.yaml
kubectl create -f services/frontend.yaml
   # Note: A ConfigMap for the frontend should now have been created.

echo ">>> Interact with the frontend by grabbing its external IP and then curling to it:"
echo ">>> kubectl get services frontend "
MY_EXTERNAL_IP=$( kubectl get services frontend )


echo ">> It may take a few seconds before the External-IP field is populated for your service."
# This is normal. Just re-run the above command every few seconds until the field is populated.
curl -ks "https://$MY_EXTERNAL_IP"
   # You should get the hello response back.

echo ">>> Use the output templating feature of kubectl to use curl as a one-liner:"
curl -ks https://`kubectl get svc frontend -o=jsonpath="{.status.loadBalancer.ingress[0].ip}"`


echo ">>> Scale a deployment"

echo ">>> Update the spec.replicas field:"
kubectl explain deployment.spec.replicas
echo ">>> Look at an explanation of this field using the kubectl explain command again"

echo ">>> The replicas field can be most easily updated using the kubectl scale command:"
kubectl scale deployment hello --replicas=5
    # Note: It may take a minute or so for all the new pods to start up.
   # After the Deployment is updated, Kubernetes will automatically update the associated ReplicaSet and start new Pods to make the total number of Pods equal 5.

echo ">>> Verify that there are now 5 hello Pods running:"
kubectl get pods | grep hello- | wc -l

echo ">>> Scale back the application: to 3 "
kubectl scale deployment hello --replicas=3

echo ">>> Verify that you have the correct number of Pods:"
kubectl get pods | grep hello- | wc -l

echo ">>> You learned about Kubernetes deployments and how to manage & scale a group of Pods:"





echo ">>> Congratulations"






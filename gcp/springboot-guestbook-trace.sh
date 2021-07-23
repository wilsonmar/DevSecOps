#!/bin/bash -e
# springboot-guestbook-trace.sh  SPRINT STATUS: Under developement
# I created this script to create the front-end
# JAVAMS04 Working with Stackdriver Trace
   # https://googlecoursera.qwiklabs.com/focuses/16724468?parent=lti_session
# 
# Lab invoked from https://www.coursera.org/learn/google-cloud-java-spring/gradedLti/AGGm2/bootstrapping-the-application-frontend-and-backend
# Highlight this command, copy it and paste it in the Google Cloud Shell within Qwiklabs:
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/gcp/springboot-guestbook-trace.sh)"


if [ -z "${MY_REGION+x}" ]; then
   MY_REGION="us-central1-c"
   gcloud config set compute/zone "$MY_REGION"
   gcloud config list
fi
echo ">>> MY_REGION=$MY_REGION"


echo ">>> Create an environment variable that contains the project ID for this lab"
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')

echo ">>> Verify that the demo application files were created"
gsutil ls gs://$PROJECT_ID

echo ">>> Copy the application folders to Cloud Shell"
gsutil -m cp -r gs://$PROJECT_ID/* ~/

echo ">>> Make the Maven wrapper scripts executable"
chmod +x ~/guestbook-frontend/mvnw
chmod +x ~/guestbook-service/mvnw


#!/bin/bash -e
# springboot-guestbook-front.sh  SPRINT STATUS: Under developement
# I created this script to create the front-end
# JAVAMS01 - Bootstrapping the Application Frontend and Backend
# https://googlecoursera.qwiklabs.com/focuses/16723634?parent=lti_session
# 
# Lab invoked from https://www.coursera.org/learn/google-cloud-java-spring/gradedLti/AGGm2/bootstrapping-the-application-frontend-and-backend
# Highlight this command, copy it and paste it in the Google Cloud Shell within Qwiklabs:
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/gcp/springboot-guestbook-front.sh)"

# Host info: uname -a

if [ -z "${MY_REGION+x}" ]; then
   MY_REGION="us-central1"
fi
echo ">>> MY_REGION=$MY_REGION"
gcloud config set compute/zone "$MY_REGION"
gcloud config list

echo ">>> Run the backend"
cd ~/
git clone https://github.com/saturnism/spring-cloud-gcp-guestbook.git

echo ">>> Make a copy of the initial version of the backend application (guestbook-service)"
cp -a ~/spring-cloud-gcp-guestbook/1-bootstrap/guestbook-service \
  ~/guestbook-service

echo ">>> Run the backend application"
cd ~/guestbook-service
./mvnw -q spring-boot:run -Dserver.port=8081  

echo ">>> Now open a second Cloud Shell console to the same virtual machine."

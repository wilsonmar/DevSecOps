#!/bin/bash -e
# springboot-guestbook-testapi.sh  SPRINT STATUS: Under developement
# I created this script to create the front-end
# JAVAMS01 - Bootstrapping the Application Frontend and Backend
# https://googlecoursera.qwiklabs.com/focuses/16723634?parent=lti_session
# 
# Lab invoked from https://www.coursera.org/learn/google-cloud-java-spring/gradedLti/AGGm2/bootstrapping-the-application-frontend-and-backend
# Highlight this command, copy it and paste it in the Google Cloud Shell within Qwiklabs:
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/gcp/springboot-guestbook-testapi.sh)"

echo ">>> In the new shell tab, list all the messages that you added through a call to the backend guestbook-service API"

curl -s http://localhost:8081/guestbookMessages

# Use jq to parse the JSON return text.
curl -s http://localhost:8081/guestbookMessages \
  | jq -r '._embedded.guestbookMessages[] | {name: .name, message: .message}'

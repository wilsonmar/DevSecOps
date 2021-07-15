#!/bin/bash -e
# springboot-guestbook-cloudsql.sh  SPRINT STATUS: Under developement
# I created this script to create the front-end
# JAVAMS02 - Configuring and Connecting to Cloud SQL at
   # https://googlecoursera.qwiklabs.com/focuses/16724328?parent=lti_session
# 
# Lab invoked from https://www.coursera.org/learn/google-cloud-java-spring/gradedLti/AGGm2/bootstrapping-the-application-frontend-and-backend
# Highlight this command, copy it and paste it in the Google Cloud Shell within Qwiklabs:
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/gcp/springboot-guestbook-cloudsql.sh)"

# Host info: uname -a

if [ -z "${MY_REGION+x}" ]; then
   MY_REGION="us-central1-c"
   gcloud config set compute/zone "$MY_REGION"
   gcloud config list
fi
echo ">>> MY_REGION=$MY_REGION"

cd ~/
if [ -d "~/spring-cloud-gcp-guestbook" ]; then
   echo ">>> Removing repo cloned..."
   rm -rv ~/spring-cloud-gcp-guestbook
fi
echo ">>> Cloning the repo for branch cloud-learning ..."
git clone --single-branch --branch cloud-learning https://github.com/saturnism/spring-cloud-gcp-guestbook.git


echo ">>> Copy the relevant folders to your home directory"
cp -a ~/spring-cloud-gcp-guestbook/1-bootstrap/guestbook-service ~/guestbook-service
cp -a ~/spring-cloud-gcp-guestbook/1-bootstrap/guestbook-frontend ~/guestbook-frontend


echo ">>> Enable Cloud SQL Administration API"
gcloud services enable sqladmin.googleapis.com

echo ">>> Confirm that Cloud SQL Administration API is enabled"
gcloud services list | grep sqladmin

echo ">>> List the Cloud SQL instances"
gcloud sql instances list

echo ">>> Create a new Cloud SQL instance"
gcloud sql instances create guestbook --region=us-central1
   # Creating Cloud SQL instance...done.
   # Created [...].
   # NAME       DATABASE_VERSION REGION       TIER              ADDRESS   STATUS
   # guestbook  MYSQL_5_6        us-central1  db-n1-standard-1  92.3.4.5  RUNNABLE

echo ">>> Create a messages database in the MySQL instance"
gcloud sql databases create messages --instance guestbook

echo ">>> Use gcloud CLI to connect to the database"
# This command temporarily allowlists the IP address for the connection.
echo ">>> Press ENTER at the following prompt to leave the password empty for this lab."
gcloud sql connect guestbook
   # The root password is empty by default.
# Allowlisting your IP for incoming connection for 5 minutes...done.
   # Connecting to database with SQL user [root].Enter password:

# Within SQL: List the databases: show databases;

# Edit guestbook-service/pom.xml in the Cloud Shell code editor 


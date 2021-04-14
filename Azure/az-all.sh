#!/usr/bin/env bash
# az-all.sh

# After you obtain a Terminal (console) in your environment,
# cd to folder, copy this line and paste in the terminal:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/Azure/az-all.sh)" -v -i

# Implements Lab https://github.com/MicrosoftLearning/AZ-303-Microsoft-Azure-Architect-Technologies/blob/master/Instructions/Labs/Module_05_Lab.md

# No need for az login within Cloud Shell.
echo "STEP 00 - Login Azure:"

# QUESTION: Why is this necessary?
# az provider show -n Microsoft.Insights
   # In Json response: 
   # az provider register --namespace 'Microsoft.Insights'

LOCATION='westus'
   # az account list-locations --query "[].{name:name}" -o table
MY_RG="NetworkWatcherRG"  # per lab   
   
echo "*** Add network watcher for LOCATION=$LOCATION"
az network watcher configure --resource-group $MY_RG --locations $LOCATION --enabled -o table

exit
az deployment sub create \
--location $LOCATION \
--template-file azuredeploy30305suba.json \
--parameters rgName=az30305a-labRG rgLocation=$LOCATION

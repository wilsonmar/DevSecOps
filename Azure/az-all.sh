#!/usr/bin/env bash
# az-all.sh

# After you obtain a Terminal (console) in your environment,
# cd to folder, copy this line and paste in the terminal:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/Azure/az-all.sh)" -v -i

# Implements Lab https://github.com/MicrosoftLearning/AZ-303-Microsoft-Azure-Architect-Technologies/blob/master/Instructions/Labs/Module_05_Lab.md

# No need for az login within Cloud Shell.
# echo "STEP 00 - Login Azure:"

# QUESTION: Why is this necessary?
# az provider show -n 'Microsoft.Insights' --query "[].{resourceType}" -o table   # this doesn't work
   # In Json response: 
   # az provider register --namespace 'Microsoft.Insights'  # expect no response.
# prevents being stuck at: Resource provider 'Microsoft.Network' used by this operation is not registered. We are registering for you.
# Works in PowerShell:
   # Register-AzureRmResourceProvider –ProviderNamespace Microsoft.Insights
# Check the status with:
   # Get-AzureRmResourceProvider –ProviderNamespace Microsoft.Insights

LOCATION='westus'
   # az account list-locations --query "[].{name:name}" -o table
MY_RG="NetworkWatcherRG"  # per lab   

echo "*** Create ResourceGroup MY_RG=$MY_RG"
# az group delete --name $MY_RG
az group create --name $MY_RG --location $LOCATION   # idempotent
   # az group list  # https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-cli
   
echo "*** Add network watcher for LOCATION=$LOCATION"
az network watcher configure --resource-group $MY_RG --locations $LOCATION --enabled -o table

# /Users/wilson_mar/gmail_acct/AZ-303-MS/Allfiles/Labs/05/azuredeploy30305suba.json

exit
az deployment sub create \
--location $LOCATION \
--template-file azuredeploy30305suba.json \
--parameters rgName=az30305a-labRG rgLocation=$LOCATION

# deploy an Azure Load Balancer Basic with its backend pool consisting of 
# a pair of Azure VMs hosting Windows Server 2019 Datacenter Core into the same availability set:
az deployment group create \
--resource-group az30305a-labRG \
--template-file azuredeploy30305rga.json \
--parameters @azuredeploy30305rga.parameters.json
   # This should take about 10 minutes.


using 'deploy-environment.bicep'

# NOT generated in VSCode from deploy-parameters.json
# Used instead of .json file
# See Matt Allford on https://www.youtube.com/watch?v=AMOj5-puoGI
# paramters.bicepparam with https://github.com/wilsonmar/azure-quickly/blob/main/parameters.bicep
# CONVENTION: Begin names with lower-case letter:

param environmentName string = 'dev'  # play, test, stag, prod, back

param locationA string = 'westeurope'
#param locationB string = 'australiaeast'
#param locationC string = 'eastus'

param tags = {
  'environment' : environmentName
  'deployedWith' : 'IaC'
}
param deployStorage bool = false
param deploymentName string = 'deploy-$(environmentName)-$(locationA)'
param resourceGroupName string = 'rg-$(environmentName)-$(locationA)'
param storageAccountName string = 'st$(environmentName)$(locationA)'
param containerName string = 'deployments'


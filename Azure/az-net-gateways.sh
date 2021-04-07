#!/usr/bin/env bash
# az-net-gateways.sh

# After you obtain a Terminal (console) in your environment,
# cd to folder, copy this line and paste in the terminal:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/Azure/az-net-gateways.sh)" -v -i

# From https://docs.microsoft.com/en-us/learn/modules/connect-on-premises-network-with-vpn-gateway/4-exercise-create-a-site-to-site-vpn-gateway-using-azure-cli-commands

#echo "STEP 00 - Login Azure:"
#az login

echo "STEP 01 - Create the PIP-VNG-Azure-VNet-1 public IP address:"
az network public-ip create \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --name PIP-VNG-Azure-VNet-1 \
    --allocation-method Dynamic

echo "STEP 02 - Create the VNG-Azure-VNet-1 virtual network:"
az network vnet create \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --name VNG-Azure-VNet-1 \
    --subnet-name GatewaySubnet 

echo "STEP 03 - Create the VNG-Azure-VNet-1 virtual network gateway:"
az network vnet-gateway create \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --name VNG-Azure-VNet-1 \
    --public-ip-address PIP-VNG-Azure-VNet-1 \
    --vnet VNG-Azure-VNet-1 \
    --gateway-type Vpn \
    --vpn-type RouteBased \
    --sku VpnGw1 \
    --no-wait

echo "Create the on-premises VPN gateway to simulate an on-premises VPN device:"

echo "STEP 04 - Create the PIP-VNG-HQ-Network public IP address:"
az network public-ip create \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --name PIP-VNG-HQ-Network \
    --allocation-method Dynamic

echo "STEP 05 - Create the VNG-HQ-Network virtual network:"
az network vnet create \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --name VNG-HQ-Network \
    --subnet-name GatewaySubnet 

echo "STEP 06 - Create the VNG-HQ-Network virtual network gateway:"
az network vnet-gateway create \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --name VNG-HQ-Network \
    --public-ip-address PIP-VNG-HQ-Network \
    --vnet VNG-HQ-Network \
    --gateway-type Vpn \
    --vpn-type RouteBased \
    --sku VpnGw1 \
    --no-wait

#Gateway creation takes approximately 30+ minutes to complete. To monitor the progress of the #gateway creation, run the following command. We're using the Linux watch command to run the az network vnet-gateway list command periodically, which enables you to .

echo "STEP 07 - monitor the progress:"
watch -d -n 5 az network vnet-gateway list \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --output table

# After each VPN gateway shows a ProvisioningState of Succeeded, you're ready to continue. Press Ctrl+C to halt the command after the gateway is created.

#ActiveActive    EnableBgp    EnablePrivateIpAddress   GatewayType    Location        Name              ProvisioningState    ResourceGroup                         ResourceGuid                          VpnType
# --------------  -----------  ------------------------ -------------  --------------  ----------------  -------------------  -----------------------------  ------------------------------------  ----------
#False           False        False                    Vpn            southcentralus  VNG-Azure-VNet-1  Succeeded            learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0  48dc714e-a700-42ad-810f-a8163ee8e001  RouteBased
#False           False        False                    Vpn            southcentralus  VNG-HQ-Network    Succeeded            learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0  49b3041d-e878-40d9-a135-58e0ecb7e48b  RouteBased

# Your virtual network gateways must be successfully deployed before you start the next exercise. A gateway can take up to 30+ minutes to complete. If the ProvisioningState does not show "Succeeded" yet, you need to wait.

# In this section, you'll update the remote gateway IP address references that are defined in the local network gateways. You can't update the local network gateways until you've created the VPN gateways and an IPv4 address is assigned to and associated with them. 

echo "STEP 08 - Check whether both virtual network gateways have been created:"
az network vnet-gateway list \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --output table

# The initial state will show Updating. You want to see Succeeded on both VNG-Azure-VNet-1 and VNG-HQ-Network.

#Name              Location    GatewayType    VpnType     VpnGatewayGeneration    EnableBgp    EnablePrivateIpAddress    Active    ResourceGuid                        ProvisioningState    ResourceGroup
#----------------  ----------  -------------  ----------  ----------------------  -----------  ------------------------  --------  ------------------------------------  -------------------  ------------------------------------------
#VNG-Azure-VNet-1  westus      Vpn            RouteBased  Generation1         False        False                     False     9a2e60e6-da57-4274-99fd-e1f8b2c0326d  Succeeded            learn-cfbcca66-16fd-423e-b688-66f242d8f09e
#VNG-HQ-Network    westus      Vpn            RouteBased  Generation1         False        False                     False     c36430ed-e6c0-4230-ae40-cf937a102bcd  Succeeded            learn-cfbcca66-16fd-423e-b688-66f242d8f09e

#Remember to wait until the lists of gateways are successfully returned. Also, remember that the local network gateway resources define the settings of the remote gateway and network that they're named after. For example, the LNG-Azure-VNet-1 local network gateway contains information like the IP address and networks for Azure-VNet-1.

echo "STEP 09 - Retrieve the IPv4 address assigned to PIP-VNG-Azure-VNet-1 in a variable:"
PIPVNGAZUREVNET1=$(az network public-ip show \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --name PIP-VNG-Azure-VNet-1 \
    --query "[ipAddress]" \
    --output tsv)
echo $PIPVNGAZUREVNET1

echo "STEP 10 - Update the LNG-Azure-VNet-1 local network gateway so that it points to the public IP address attached to the VNG-Azure-VNet-1 virtual network gateway"
az network local-gateway update \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --name LNG-Azure-VNet-1 \
    --gateway-ip-address $PIPVNGAZUREVNET1

echo "STEP 11 - Retrieve the IPv4 address assigned to PIP-VNG-HQ-Network in a variable."
PIPVNGHQNETWORK=$(az network public-ip show \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --name PIP-VNG-HQ-Network \
    --query "[ipAddress]" \
    --output tsv)
echo $PIPVNGHQNETWORK

echo "STEP 12 - Update the LNG-HQ-Network local network gateway so that it points to the "
echo "          public IP address attached to the VNG-HQ-Network virtual network gateway:"
az network local-gateway update \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --name LNG-HQ-Network \
    --gateway-ip-address $PIPVNGHQNETWORK

# You'll now complete the configuration by creating the connections from each VPN gateway to the local network gateway that contains the public IP address references for that gateway's remote network.

echo "STEP 13 - Create the shared key to use for the connections:"

# replace <shared key> with a text string to use for the IPSec pre-shared key. 
# The pre-shared key is a string of printable ASCII characters no longer than 128 characters. You'll use this pre-shared key on both connections.

SHAREDKEY=123456789

# In production environments, we recommend using a string of printable ASCII characters no longer than 128 characters.

# Remember that LNG-HQ-Network contains a reference to the IP address on your simulated on-premises VPN device. 
echo "STEP 14 - Create a connection from VNG-Azure-VNet-1 to LNG-HQ-Network:"
az network vpn-connection create \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --name Azure-VNet-1-To-HQ-Network \
    --vnet-gateway1 VNG-Azure-VNet-1 \
    --shared-key $SHAREDKEY \
    --local-gateway2 LNG-HQ-Network

#Remember that LNG-Azure-VNet-1 contains a reference to the public IP address associated with the VNG-Azure-VNet-1 VPN gateway. 
#This connection would normally be created from your on-premises device. 

echo "STEP 15 - Create a connection from VNG-HQ-Network to LNG-Azure-VNet-1:"
az network vpn-connection create \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --name HQ-Network-To-Azure-VNet-1  \
    --vnet-gateway1 VNG-HQ-Network \
    --shared-key $SHAREDKEY \
    --local-gateway2 LNG-Azure-VNet-1

# You've now finished the configuration of the site-to-site connection. 
# This may take a few minutes, but the tunnels should automatically connect and become active.

echo "STEP 16 - Confirm that the VPN tunnels are connected"
echo "that Azure-VNet-1-To-HQ-Network is connected"
az network vpn-connection show \
    --resource-group learn-1c07ea0e-dc95-4522-9ae3-0ee8da9786f0 \
    --name Azure-VNet-1-To-HQ-Network  \
    --output table \
    --query '{Name:name,ConnectionStatus:connectionStatus}'

# If the ConnectionStatus shows as Connecting or Unknown, wait a minute or two and 
# rerun the command. The connections can take a few minutes to fully connect.
#Name                        ConnectionStatus
#--------------------------  ------------------
#Azure-VNet-1-To-HQ-Network  Connected

# The site-to-site configuration is now complete. Your final topology, including the subnets, and connections, with logical connection points, appears in the following diagram. Virtual machines deployed in the Services and Applications subnets can now communicate with each other, now that the VPN connections have been successfully established.

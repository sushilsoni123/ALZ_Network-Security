###############################################################
################# PROVIDER AND BACKEND #######################
##############################################################

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
  }
   backend "azurerm" {
      resource_group_name = "mgmt_rg"
      storage_account_name = "demoterraformvci"             # Blob Storage account 
      container_name = "state-files"                        # folder name
      key = "hubpeeringroutes.tfstate"                        # tfstate file name
      subscription_id = "dbbf834e-d172-43ce-9e9b-e698443b0ce8" # subscription id where blob staorage account sits. Generally in genkins/mgmt/ci-cd subscrip.
    }
}
provider "azurerm" {
  # Configuration options
  features {}
 subscription_id = var.subscription_id     # subscription id where actual config to be done.
}


###############################################################
################# VNET PEERING TO SPOKES/RHUB ################
##############################################################


# RHUB Details
data "azurerm_resource_group" "rhub_rg" {
  name = "rhub_rg"
}

data "azurerm_virtual_network" "rhub_vnet" {
  name = "rhub_vnet"
  resource_group_name = "rhub_rg"
}


resource "azurerm_virtual_network_peering" "Routablehub_to_Opco1spoke1" {
  name                      = "Routablehub-to-Opco1spoke1"
  resource_group_name       = data.azurerm_resource_group.rhub_rg.name
  virtual_network_name      = data.azurerm_virtual_network.rhub_vnet.name
  remote_virtual_network_id = "/subscriptions/dbbf834e-d172-43ce-9e9b-e698443b0ce8/resourceGroups/spoke1_rg/providers/Microsoft.Network/virtualNetworks/spoke1_vnet"
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "Routablehub_to_Opco1spoke2" {
  name                      = "Routablehub-to-Opco1spoke2"
  resource_group_name       = data.azurerm_resource_group.rhub_rg.name
  virtual_network_name      = data.azurerm_virtual_network.rhub_vnet.name
  remote_virtual_network_id = "/subscriptions/dbbf834e-d172-43ce-9e9b-e698443b0ce8/resourceGroups/spoke2_rg/providers/Microsoft.Network/virtualNetworks/spoke2_vnet"
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
}
/*
resource "azurerm_virtual_network_peering" "Routablehub_to_Opco1spoke3" {
  name                      = "Routablehub_to_Opco1spoke3"
  resource_group_name       = data.azurerm_resource_group.rhub_rg.name
  virtual_network_name      = data.azurerm_virtual_network.rhub_vnet.name
  remote_virtual_network_id = "/subscriptions/dbbf834e-d172-43ce-9e9b-e698443b0ce8/resourceGroups/spoke3_rg/providers/Microsoft.Network/virtualNetworks/spoke3_vnet"
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
}
*/

#############################################
###### FROM SPOKES TO ROUTABLEHUB ###########
#############################################

############################################ SPOKE1 Details
data "azurerm_resource_group" "spoke1_rg" {
  name = "spoke1_rg"
}
data "azurerm_virtual_network" "spoke1_vnet" {
  name = "spoke1_vnet"
  resource_group_name = "spoke1_rg"
}

#peering to spoke1
resource "azurerm_virtual_network_peering" "Opco1spoke1_to_Routablehub" {
  name                      = "Opco1spoke1_to_Routablehub"
  resource_group_name       = data.azurerm_resource_group.spoke1_rg.name
  virtual_network_name      = data.azurerm_virtual_network.spoke1_vnet.name
  remote_virtual_network_id = "/subscriptions/dbbf834e-d172-43ce-9e9b-e698443b0ce8/resourceGroups/rhub_rg/providers/Microsoft.Network/virtualNetworks/rhub_vnet"
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = true
	
  depends_on = [
    azurerm_virtual_network_peering.Routablehub_to_Opco1spoke1
  ]

}

############################### SPOKE2 Details

data "azurerm_resource_group" "spoke2_rg" {
  name = "spoke2_rg"
}
data "azurerm_virtual_network" "spoke2_vnet" {
  name = "spoke2_vnet"
  resource_group_name = "spoke2_rg"
}
#peering to spoke2
resource "azurerm_virtual_network_peering" "Opco1spoke2_to_Routablehub" {
  name                      = "Opco1spoke2_to_Routablehub"
  resource_group_name       = data.azurerm_resource_group.spoke2_rg.name
  virtual_network_name      = data.azurerm_virtual_network.spoke2_vnet.name
  remote_virtual_network_id = "/subscriptions/dbbf834e-d172-43ce-9e9b-e698443b0ce8/resourceGroups/rhub_rg/providers/Microsoft.Network/virtualNetworks/rhub_vnet"
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = true
	
  depends_on = [
    azurerm_virtual_network_peering.Routablehub_to_Opco1spoke2
  ]

}

############################### SPOKE3 Details
/*
data "azurerm_resource_group" "spoke3_rg" {
  name = "spoke3_rg"
}
data "azurerm_virtual_network" "spoke3_vnet" {
  name = "spoke3_vnet"
  resource_group_name = "spoke3_rg"
}
#peering to spoke3

resource "azurerm_virtual_network_peering" "Opco1spoke3_to_Routablehub" {
  name                      = "Opco1spoke3_to_Routablehub"
  resource_group_name       = data.azurerm_resource_group.spoke3_rg.name
  virtual_network_name      = data.azurerm_virtual_network.spoke3_vnet.name
  remote_virtual_network_id = "/subscriptions/dbbf834e-d172-43ce-9e9b-e698443b0ce8/resourceGroups/rhub_rg/providers/Microsoft.Network/virtualNetworks/rhub_vnet"
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = true
	
  depends_on = [
    azurerm_virtual_network_peering.Routablehub_to_Opco1spoke3
  ]

}
*/
###############################################################
################# ROUTE ADDITION TO SPOKES ###################
##############################################################

data "azurerm_route_table" "gatewaysubnet_rt" {
  name = "gatewaysubnet_rt"
  resource_group_name = "rhub_rg"
}


resource "azurerm_route" "for_spoke1_subnet1" {
  name                   = "for_spoke1_subnet1"
  resource_group_name       = data.azurerm_resource_group.rhub_rg.name
  route_table_name       = data.azurerm_route_table.gatewaysubnet_rt.name
  address_prefix = "10.9.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.5.6.4"  
  # Internal IP of Azure Firewall
	
}

resource "azurerm_route" "for_spoke2_subnet1" {
  name                   = "for_spoke2_subnet1"
  resource_group_name       = data.azurerm_resource_group.rhub_rg.name
  route_table_name       = data.azurerm_route_table.gatewaysubnet_rt.name
  address_prefix = "10.10.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.5.6.4"  
  # Internal IP of Azure Firewall
}
/*
resource "azurerm_route" "for_spoke3_subnet1" {
  name                   = "for_spoke3_subnet1"
  resource_group_name       = data.azurerm_resource_group.rhub_rg.name
  route_table_name       = data.azurerm_route_table.gatewaysubnet_rt.name
  address_prefix = "10.11.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.5.6.4"  
  # Internal IP of Azure Firewall
}

*/

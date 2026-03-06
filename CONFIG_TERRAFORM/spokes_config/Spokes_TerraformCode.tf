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
      key = "spokes.tfstate"                                  # tfstate file name
      subscription_id = "dbbf834e-d172-43ce-9e9b-e698443b0ce8" # subscription id where blob staorage account sits. Generally in genkins/mgmt/ci-cd subscrip.
    }
}
provider "azurerm" {
  # Configuration options
  features {}
 subscription_id = var.subscription_id    # subscription id where actual config to be done.
}

resource "azurerm_resource_group" "spoke1_rg" {
  name     = "spoke1_rg"
  location = var.cloud_region
}

resource "azurerm_virtual_network" "spoke1_vnet" {
  name = "spoke1_vnet"
  location = var.cloud_region
  resource_group_name = azurerm_resource_group.spoke1_rg.name
  address_space = ["10.9.0.0/16"]
}
resource "azurerm_subnet" "spoke1_vm_subnet" {
  name = "spoke1_vm_subnet"
  address_prefixes = ["10.9.0.0/24"]
  resource_group_name = azurerm_resource_group.spoke1_rg.name
  virtual_network_name = azurerm_virtual_network.spoke1_vnet.name
}


resource "azurerm_route_table" "spoke1_EndUSerSubnet_rt" {
  name                = "spoke1_EnduserSubnet_rt"
  location =              var.cloud_region
  resource_group_name = azurerm_resource_group.spoke1_rg.name
	bgp_route_propagation_enabled = false
}
resource "azurerm_route" "default_spoke1" {
  name                   = "default_spoke1"
  resource_group_name = azurerm_resource_group.spoke1_rg.name
  route_table_name       = azurerm_route_table.spoke1_EndUSerSubnet_rt.name
  address_prefix = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.5.6.4"  
  # Internal IP of Azure Firewall in Routable hub
}


resource "azurerm_subnet_route_table_association" "spoke1_RT_Association" {
  subnet_id      = azurerm_subnet.spoke1_vm_subnet.id
  route_table_id = azurerm_route_table.spoke1_EndUSerSubnet_rt.id
}

########## Virtual Machine Creation #################

resource "azurerm_network_interface" "spoke1_nic1" {
  name                = "spoke1_nic1"
  location =              var.cloud_region
  resource_group_name = azurerm_resource_group.spoke1_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke1_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_network_security_group" "Spoke1-nsg" {
  name                = "Spoke1-nsg"
  location =              var.cloud_region
  resource_group_name = azurerm_resource_group.spoke1_rg.name

#### Switch to azurerm_network_security_rule per rule ### or use lifecycle block {} ##

  security_rule {
    name                       = "allow-http"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes      = ["10.7.0.0/16", "10.10.0.0/16", "10.11.0.0/16"]
    destination_address_prefix = "*"
  }
security_rule {
    name                       = "allow-ssh"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes      = ["10.7.0.0/16", "10.10.0.0/16", "10.11.0.0/16"]
    destination_address_prefix = "*"
  }
security_rule {
    name                       = "allow-icmp"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes      = ["10.7.0.0/16", "10.10.0.0/16", "10.11.0.0/16"]
    destination_address_prefix = "*"
  }


}

resource "azurerm_network_interface_security_group_association" "spoke1_NIC_Association" {
  network_interface_id      = azurerm_network_interface.spoke1_nic1.id
  network_security_group_id = azurerm_network_security_group.Spoke1-nsg.id
}

resource "azurerm_virtual_machine" "spoke1_user_vm" {
  name                  = "spoke1_user_vm"
  location =              var.cloud_region
  resource_group_name = azurerm_resource_group.spoke1_rg.name
  network_interface_ids = [azurerm_network_interface.spoke1_nic1.id]
  vm_size               = "Standard_B1s"
  delete_os_disk_on_termination    = true
	
 boot_diagnostics {
    enabled     = true
    storage_uri = "https://demoterraformvci.blob.core.windows.net/"
  }


  storage_os_disk {
    name              = "os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
		
  }

  storage_image_reference {
   publisher = "Canonical"
   offer     = "0001-com-ubuntu-server-jammy"
   sku       = "22_04-lts-gen2"
   version   = "latest"
  }

  os_profile {
    computer_name  = "spoke1-user-vm"
    admin_username = "adminuser"
    admin_password = "Password1234!"
    custom_data    = filebase64("${path.module}/cloud-init.txt")
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
		

}


##################################################################
######################## LM spoke-2 #############################
#################################################################


resource "azurerm_resource_group" "spoke2_rg" {
  name     = "spoke2_rg"
  location = var.cloud_region
}

resource "azurerm_virtual_network" "spoke2_vnet" {
  name = "spoke2_vnet"
  location = var.cloud_region
  resource_group_name = azurerm_resource_group.spoke2_rg.name
  address_space = ["10.10.0.0/16"]
}
resource "azurerm_subnet" "Spoke2_VM_Subnet" {
  name = "Spoke2_VM_Subnet"
  address_prefixes = ["10.10.0.0/24"]
  resource_group_name = azurerm_resource_group.spoke2_rg.name
  virtual_network_name = azurerm_virtual_network.spoke2_vnet.name
}


resource "azurerm_route_table" "spoke2_EndUSerSubnet_rt" {
  name                = "spoke2_EnduserSubnet_rt"
  location =              var.cloud_region
  resource_group_name = azurerm_resource_group.spoke2_rg.name
	bgp_route_propagation_enabled = false
}

resource "azurerm_route" "default_spoke2" {
  name                   = "default_spoke2"
  resource_group_name = azurerm_resource_group.spoke2_rg.name
  route_table_name       = azurerm_route_table.spoke2_EndUSerSubnet_rt.name
  address_prefix = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.5.6.4"  
  # Internal IP of Azure Firewall in Routable hub
}

resource "azurerm_subnet_route_table_association" "spoke2_RT_Association" {
  subnet_id      = azurerm_subnet.Spoke2_VM_Subnet.id
  route_table_id = azurerm_route_table.spoke2_EndUSerSubnet_rt.id
}

/*
resource "azurerm_virtual_network_peering" "spoke2_to_Routablehub" {
  name                      = "spoke2-to-Routablehub"
  resource_group_name       = azurerm_resource_group.spoke2_rg.name
  virtual_network_name      = azurerm_virtual_network.spoke2_vnet.name
  remote_virtual_network_id = "/subscriptions/dbbf834e-d172-43ce-9e9b-e698443b0ce8/resourceGroups/rhub_rg/providers/Microsoft.Network/virtualNetworks/rhub_vnet"
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = true
}
*/
resource "azurerm_network_security_group" "Spoke2-nsg" {
  name                = "Spoke2-nsg"
  location =              var.cloud_region
  resource_group_name = azurerm_resource_group.spoke2_rg.name

#### Switch to azurerm_network_security_rule per rule ### or use lifecycle block {} ##

 


  security_rule {
    name                       = "allow-http"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes      = ["10.7.0.0/16", "10.9.0.0/16", "10.11.0.0/16"]
    destination_address_prefix = "*"
  }
security_rule {
    name                       = "allow-ssh"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes      = ["10.7.0.0/16", "10.9.0.0/16", "10.11.0.0/16"]
    destination_address_prefix = "*"
  }
security_rule {
    name                       = "allow-icmp"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes      = ["10.7.0.0/16", "10.9.0.0/16", "10.11.0.0/16"]  ###single subnet specified as "10.7.1.0"- or better provide as list(string) if many subs like ["10.7.0.0/16", "10.10.1.0/24"]
    destination_address_prefix = "*"
  }


}

resource "azurerm_network_interface" "spoke2_nic1" {
  name                = "spoke2_nic1"
  location =              var.cloud_region
  resource_group_name = azurerm_resource_group.spoke2_rg.name
	  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.Spoke2_VM_Subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "spoke2_NIC_Association" {
  network_interface_id      = azurerm_network_interface.spoke2_nic1.id
  network_security_group_id = azurerm_network_security_group.Spoke2-nsg.id
}




resource "azurerm_virtual_machine" "spoke2_user_vm" {
  name                  = "spoke2_user_vm"
  location =              var.cloud_region
  resource_group_name = azurerm_resource_group.spoke2_rg.name
  network_interface_ids = [azurerm_network_interface.spoke2_nic1.id]
  vm_size               = "Standard_B1s"
	delete_os_disk_on_termination    = true
  
	
 boot_diagnostics {
    enabled     = true
    storage_uri = "https://demoterraformvci.blob.core.windows.net/"
  }

  storage_os_disk {
    name              = "os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
   publisher = "Canonical"
   offer     = "0001-com-ubuntu-server-jammy"
   sku       = "22_04-lts-gen2"
   version   = "latest"
  }

  os_profile {
    computer_name  = "spoke2-user-vm"
    admin_username = "adminuser"
    admin_password = "Password1234!"
    custom_data    = filebase64("${path.module}/cloud-init.txt")
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}





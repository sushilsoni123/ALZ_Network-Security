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
      key = "spoke3.tfstate"                                 # tfstate file name
      subscription_id = "dbbf834e-d172-43ce-9e9b-e698443b0ce8" # subscription id where blob staorage account sits. Generally in genkins/mgmt/ci-cd subscrip.
    }
}
provider "azurerm" {
  # Configuration options
  features {}
 subscription_id = var.subscription_id    # subscription id where actual config to be done.
}

resource "azurerm_resource_group" "spoke3_rg" {
  name     = "spoke3_rg"
  location = "North Europe"
}

resource "azurerm_virtual_network" "spoke3_vnet" {
  name = "spoke3_vnet"
  location = "North Europe"
  resource_group_name = azurerm_resource_group.spoke3_rg.name
  address_space = ["10.11.0.0/16"]
}
resource "azurerm_subnet" "spoke3_vm_subnet" {
  name = "spoke3_vm_subnet"
  address_prefixes = ["10.11.0.0/24"]
  resource_group_name = azurerm_resource_group.spoke3_rg.name
  virtual_network_name = azurerm_virtual_network.spoke3_vnet.name
}


resource "azurerm_route_table" "spoke3_EndUSerSubnet_rt" {
  name                = "spoke3_EnduserSubnet_rt"
  location =              "North Europe"
  resource_group_name = azurerm_resource_group.spoke3_rg.name
	bgp_route_propagation_enabled = false
}
resource "azurerm_route" "default_spoke3" {
  name                   = "default_spoke3"
  resource_group_name = azurerm_resource_group.spoke3_rg.name
  route_table_name       = azurerm_route_table.spoke3_EndUSerSubnet_rt.name
  address_prefix = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.5.6.4"  
  # Internal IP of Azure Firewall in Routable hub
}


resource "azurerm_subnet_route_table_association" "spoke3_RT_Association" {
  subnet_id      = azurerm_subnet.spoke3_vm_subnet.id
  route_table_id = azurerm_route_table.spoke3_EndUSerSubnet_rt.id
}

########## Virtual Machine Creation #################

resource "azurerm_network_interface" "spoke3_nic1" {
  name                = "spoke3_nic1"
  location =              "North Europe"
  resource_group_name = azurerm_resource_group.spoke3_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke3_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_network_interface_security_group_association" "spoke3_NIC_Association" {
  network_interface_id      = azurerm_network_interface.spoke3_nic1.id
  network_security_group_id = azurerm_network_security_group.Spoke3-nsg.id
}


resource "azurerm_network_security_group" "Spoke3-nsg" {
  name                = "Spoke3-nsg"
  location =              "North Europe"
  resource_group_name = azurerm_resource_group.spoke3_rg.name

  security_rule {
    name                       = "allow-http"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes      = ["10.7.0.0/16", "10.10.0.0/16", "10.9.0.0/16"]
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
    source_address_prefixes      = ["10.7.0.0/16", "10.10.0.0/16", "10.9.0.0/16"]
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
    source_address_prefixes      = ["10.7.0.0/16", "10.10.0.0/16", "10.9.0.0/16"]
    destination_address_prefix = "*"
  }


}

resource "azurerm_virtual_machine" "spoke3_user_vm" {
  name                  = "spoke3-user-vm"
  location =              "North Europe"
  resource_group_name = azurerm_resource_group.spoke3_rg.name
  network_interface_ids = [azurerm_network_interface.spoke3_nic1.id]
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
    computer_name  = "os-profile-vm"
    admin_username = "adminuser"
    admin_password = var.vmpassword
    custom_data    = filebase64("${path.module}/cloud-init.txt")
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}


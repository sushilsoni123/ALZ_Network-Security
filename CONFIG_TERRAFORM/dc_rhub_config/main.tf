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
      key = "dc-rhub.tfstate"                                 # tfstate file name
      subscription_id = "dbbf834e-d172-43ce-9e9b-e698443b0ce8" # subscription id where blob staorage account sits. Generally in genkins/mgmt/ci-cd subscrip.
    }
}
provider "azurerm" {
  # Configuration options
  features {}
  subscription_id = var.subscription_id     # subscription id where actual config to be done.
  # use-oidc=true
}


#####################################################################
###################### Swindon-DC ###################################
####################################################################



##### Creation of VNET and Subnets ###############

resource "azurerm_resource_group" "dc_rg" {
  name = var.dc_rg_name
  location = var.dc_region
 }



resource "azurerm_virtual_network" "dc_vnet" {
  name = "dc_vnet"
  location = var.dc_region
  resource_group_name = azurerm_resource_group.dc_rg.name
  address_space = var.dc_cidr_id
}
resource "azurerm_subnet" "dc_vm_subnet" {
  name = "dc_vm_subnet"
  address_prefixes = var.dc_vm_subnet
  resource_group_name = azurerm_resource_group.dc_rg.name
  virtual_network_name = azurerm_virtual_network.dc_vnet.name
}
resource "azurerm_subnet" "dc_gateway_subnet" {
  name = "GatewaySubnet"
  address_prefixes = var.dc_gateway_subnet
  resource_group_name = azurerm_resource_group.dc_rg.name
  virtual_network_name = azurerm_virtual_network.dc_vnet.name
}

resource "azurerm_public_ip" "dc_pip1" {
  name                = "dc_pip1"
  location            = var.dc_region
  resource_group_name = azurerm_resource_group.dc_rg.name
  allocation_method = "Static" # Static or Dynamic supported [2](https://registry.terraform.io/providers/hashicorp/azurerm/4.60.0/docs/resources/public_ip)
  sku               = "Standard"
	zones             = ["1", "2", "3"]
}

resource "azurerm_public_ip" "dc_pip2" {
  name                = "dc_pip2"
  location            = var.dc_region
  resource_group_name = azurerm_resource_group.dc_rg.name
  allocation_method = "Static" # Static or Dynamic supported [2](https://registry.terraform.io/providers/hashicorp/azurerm/4.60.0/docs/resources/public_ip)
  sku               = "Standard"
	zones             = ["1", "2", "3"]
}


resource "azurerm_virtual_network_gateway" "dc_vng" {
  name                = "dc_vng"
  location            = var.dc_region
  resource_group_name = azurerm_resource_group.dc_rg.name
  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "VpnGw2AZ"

  ip_configuration {
    name                          = "vnetGatewayConfig1"
    public_ip_address_id          = azurerm_public_ip.dc_pip1.id  ##use resource id if already created beforehand.
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.dc_gateway_subnet.id
  }
  ip_configuration {
    name                          = "vnetGatewayConfig2"
    public_ip_address_id          = azurerm_public_ip.dc_pip2.id ##use resource id if already created beforehand.

    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.dc_gateway_subnet.id
  }
  bgp_settings {
    asn                          = var.dc_local_asn
    peer_weight                  = 0
   
  }
}



resource "azurerm_local_network_gateway" "Opco1_lng1" {
  name                = "Opco1_lng1"
  location            = var.dc_region
  resource_group_name = azurerm_resource_group.dc_rg.name
  gateway_address     = azurerm_public_ip.rhub_pip1.ip_address
  address_space       = var.dc_accepted_prefixes
  bgp_settings {
    asn             = var.dc_remote_asn
    bgp_peering_address = var.dc_bgp_peer1
  }
}

resource "azurerm_local_network_gateway" "Opco1_lng2" {
  name                = "Opco1_lng2"
  location            = var.dc_region
  resource_group_name = azurerm_resource_group.dc_rg.name
  gateway_address     = azurerm_public_ip.rhub_pip2.ip_address
  address_space       = var.dc_accepted_prefixes
  bgp_settings {
    asn             = var.dc_remote_asn
    bgp_peering_address = var.dc_bgp_peer2
  }
}


resource "azurerm_virtual_network_gateway_connection" "Opco1_Tunnel1" {
  name                           = "Opco1_Tunnel1"
  location                       = var.dc_region
  resource_group_name            = azurerm_resource_group.dc_rg.name
  virtual_network_gateway_id     = azurerm_virtual_network_gateway.dc_vng.id
  local_network_gateway_id       = azurerm_local_network_gateway.Opco1_lng1.id
  type                           = "IPsec"
  shared_key                     = var.bgp_keyword
  enable_bgp                     = true
}


resource "azurerm_virtual_network_gateway_connection" "Opco1_Tunnel2" {
  name                           = "Opco1_Tunnel2"
  location                       = var.dc_region
  resource_group_name            = azurerm_resource_group.dc_rg.name
  virtual_network_gateway_id     = azurerm_virtual_network_gateway.dc_vng.id
  local_network_gateway_id       = azurerm_local_network_gateway.Opco1_lng2.id
  type                           = "IPsec"
  shared_key                     = var.bgp_keyword
  enable_bgp                     = true
}


########## Virtual Machine Creation #################

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location =              var.dc_region
  resource_group_name = azurerm_resource_group.dc_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dc_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_network_security_group" "dc_vm_nsg" {
  name                = "dc_vm_nsg"
  location =              var.dc_region
  resource_group_name = azurerm_resource_group.dc_rg.name

  security_rule {
    name                       = "allow-http"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
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
    source_address_prefix      = "*"
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
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


}

resource "azurerm_network_interface_security_group_association" "NIC_Association" {
  network_interface_id      = azurerm_network_interface.nic1.id
  network_security_group_id = azurerm_network_security_group.dc_vm_nsg.id
}

resource "azurerm_virtual_machine" "dc_user_VM" {
  name                  = "dc-user-vm"
  location =              var.dc_region
  resource_group_name = azurerm_resource_group.dc_rg.name
  network_interface_ids = [azurerm_network_interface.nic1.id]
  vm_size               = "Standard_D2s_v3"


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
    computer_name  = "dc-user-vm"
    admin_username = "adminuser"
    admin_password = "Password1234!"
    custom_data    = filebase64("${path.module}/cloud-init.txt")
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
	
}



#####################################################################
###################### Dublin-RHUB #################################
####################################################################



resource "azurerm_resource_group" "rhub_rg" {
  name     = var.rhub_rg_name
  location = var.rhub_region
}

################ Creation of Vnet and Subnets #######################################

resource "azurerm_virtual_network" "rhub_vnet" {
  name = "rhub_vnet"
  location = var.rhub_region
  resource_group_name = azurerm_resource_group.rhub_rg.name
  address_space = ["10.5.0.0/16"]
}

resource "azurerm_subnet" "rhub_gateway_subnet" {
  name = "GatewaySubnet"
  resource_group_name = azurerm_resource_group.rhub_rg.name
  address_prefixes = var.rhub_gateway_subnet
  virtual_network_name = azurerm_virtual_network.rhub_vnet.name
}


############ Creation of Public ips, will be required for VPN Gateways ##################

resource "azurerm_public_ip" "rhub_pip1" {
  name                = "rhub_pip1"
  location            =  var.rhub_region
  resource_group_name = azurerm_resource_group.rhub_rg.name
  allocation_method = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}
resource "azurerm_public_ip" "rhub_pip2" {
  name                = "rhub_pip2"
  location            =  var.rhub_region
  resource_group_name = azurerm_resource_group.rhub_rg.name
  allocation_method = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
 
}

############ Creation of VPN Gateways in active-active fashion ################

resource "azurerm_virtual_network_gateway" "rhub_vng" {
  name                = "rhub_vng"
  resource_group_name = azurerm_resource_group.rhub_rg.name
  location      = var.rhub_region
  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "VpnGw2AZ"

  ip_configuration {
    name                          = "vnetGatewayConfig1"
    public_ip_address_id          = azurerm_public_ip.rhub_pip1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.rhub_gateway_subnet.id
  }
  ip_configuration {
    name                          = "vnetGatewayConfig2"
    public_ip_address_id          = azurerm_public_ip.rhub_pip2.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.rhub_gateway_subnet.id
  }
  bgp_settings {
    asn                          = var.rhub_local_asn
    peer_weight                  = 0
    }

}

########### Creation of Local network Gateways ########################

resource "azurerm_local_network_gateway" "cedge-1" {
  name                = "cedge-1"
  resource_group_name  = azurerm_resource_group.rhub_rg.name
  location     = var.rhub_region
  gateway_address     = azurerm_public_ip.dc_pip1.ip_address
  address_space       = var.rhub_accepted_prefixes
  bgp_settings {
    asn             = var.rhub_remote_asn
    bgp_peering_address = var.rhub_bgp_peer1
  }
}

resource "azurerm_local_network_gateway" "cedge-2" {
  name                = "cedge-2"
  resource_group_name  = azurerm_resource_group.rhub_rg.name
  location      = var.rhub_region
  gateway_address     = azurerm_public_ip.dc_pip2.ip_address
  address_space       = var.rhub_accepted_prefixes
  bgp_settings {
    asn             = var.rhub_remote_asn
    bgp_peering_address = var.rhub_bgp_peer2
  }
}

########### Creation of IPSEC VPN Tunnels ###############

resource "azurerm_virtual_network_gateway_connection" "cedge_tunnel1" {
  name                           = "cedge_tunnel1"
  resource_group_name = azurerm_resource_group.rhub_rg.name
  location                       = var.rhub_region
  virtual_network_gateway_id     = azurerm_virtual_network_gateway.rhub_vng.id
  local_network_gateway_id       = azurerm_local_network_gateway.cedge-1.id
  type                           = "IPsec"
  shared_key                     = var.bgp_keyword
  enable_bgp                     = true
}

resource "azurerm_virtual_network_gateway_connection" "cedge-tunnel2" {
  name                           = "cedge-tunnel2"
  resource_group_name = azurerm_resource_group.rhub_rg.name
  location                       = var.rhub_region
  virtual_network_gateway_id     = azurerm_virtual_network_gateway.rhub_vng.id
  local_network_gateway_id       = azurerm_local_network_gateway.cedge-2.id
  type                           = "IPsec"
  shared_key                     = var.bgp_keyword
  enable_bgp                     = true
}


#####################firewall section#########################


resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rhub_rg.name
  virtual_network_name = azurerm_virtual_network.rhub_vnet.name
  address_prefixes     = ["10.5.6.0/24"]
}

#Create the Public IP Address:

resource "azurerm_public_ip" "firewall_pip" {
  name                = "FirewallPip"
  resource_group_name  = azurerm_resource_group.rhub_rg.name
  location      = var.rhub_region
  allocation_method   = "Static"
  sku                 = "Standard"
}

#Define the Firewall Policy:
resource "azurerm_firewall_policy" "firewall_policy" {
  name                = "FirewallPolicy"
  location            = var.rhub_region
  resource_group_name = azurerm_resource_group.rhub_rg.name
}

#Create the Azure Firewall:
resource "azurerm_firewall" "firewall" {
  name                = "AzureFirewall"
  resource_group_name = azurerm_resource_group.rhub_rg.name
  location      = var.rhub_region
  sku_name = "AZFW_VNet"
  sku_tier = "Standard"
  ip_configuration {
    name                 = "ipconfiguration"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }
  timeouts {
    create = "90m"
    update = "90m"
    delete = "90m"
  }
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
}



resource "azurerm_route_table" "gatewaysubnet_rt" {
  name                = "gatewaysubnet_rt"
  location =              var.rhub_region
  resource_group_name       = azurerm_resource_group.rhub_rg.name
  depends_on = [azurerm_firewall.firewall]
}

resource "azurerm_subnet_route_table_association" "RT_Association" {
  subnet_id      = azurerm_subnet.rhub_gateway_subnet.id
  route_table_id = azurerm_route_table.gatewaysubnet_rt.id
  depends_on = [azurerm_firewall.firewall]
  timeouts {
    create = "90m" 
    delete = "90m"
  }
}
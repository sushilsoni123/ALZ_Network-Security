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
      key = "hubfirewallrule.tfstate"                         # tfstate file name
      subscription_id = "dbbf834e-d172-43ce-9e9b-e698443b0ce8" # subscription id where blob staorage account sits. Generally in genkins/mgmt/ci-cd subscrip.
    }
}
provider "azurerm" {
  # Configuration options
  features {}
 subscription_id = var.subscription_id    # subscription id where actual config to be done.
}


###############################################################
################# FIREWALL RULE ADDITION ######################
##############################################################

data "azurerm_firewall_policy" "policy" {
  name                = var.FirewallPolicy
  resource_group_name = "rhub_rg"
}

# Engineer B: a different RCG (priority 160) – independent of A’s
resource "azurerm_firewall_policy_rule_collection_group" "rule_collection_group" {
  name                = "RuleCollectionGroup"
  firewall_policy_id  = data.azurerm_firewall_policy.policy.id
  priority            = 100

  network_rule_collection {
    name     = "NetRuleCollection"
    priority = 100
    action   = "Allow"

#### internet for all spokes

   rule {
    name                  = "spokes-to-internet"
    protocols             = ["TCP", "UDP"]
    source_addresses      = ["10.9.0.0/24", "10.10.0.0/24", "10.11.0.0/24"]
    destination_addresses = ["0.0.0.0/0"]
    destination_ports     = ["80", "443"]
   }
###dc to spoke1

    rule {
      name       = "inc-1"
      source_addresses = ["10.7.0.0/16"]
      destination_addresses = ["10.9.0.0/16"]
      destination_ports = ["*"]
      protocols = ["ICMP"]
    }
    rule {
      name                  = "inc-2"
      source_addresses      = ["10.7.0.0/16"]
      destination_addresses = ["10.9.0.0/16"]
      destination_ports     = ["80"]
      protocols             = ["TCP"]
    }
		rule {
      name                  = "inc-3"
      source_addresses      = ["10.7.0.0/16"]
      destination_addresses = ["10.9.0.0/16"]
      destination_ports     = ["22"]
      protocols             = ["TCP"]
    }

###dc to spoke2

		rule {
      name       = "inc-4"
      source_addresses = ["10.7.0.0/16"]
      destination_addresses = ["10.10.0.0/16"]
      destination_ports = ["*"]
      protocols = ["ICMP"]
    }
    rule {
      name                  = "inc-5"
      source_addresses      = ["10.7.0.0/16"]
      destination_addresses = ["10.10.0.0/16"]
      destination_ports     = ["80"]
      protocols             = ["TCP"]
    }
		rule {
      name                  = "inc-6"
      source_addresses      = ["10.7.0.0/16"]
      destination_addresses = ["10.10.0.0/16"]
      destination_ports     = ["22"]
      protocols             = ["TCP"]
    }

####spoke2 to spoke3
/*
		rule {
      name       = "inc-7"
      source_addresses = ["10.9.0.0/16"]
      destination_addresses = ["10.11.0.0/16"]
      destination_ports = ["*"]
      protocols = ["ICMP"]
    }
    rule {
      name                  = "inc-8"
      source_addresses      = ["10.9.0.0/16"]
      destination_addresses = ["10.11.0.0/16"]
      destination_ports     = ["80"]
      protocols             = ["TCP"]
    }
		rule {
      name                  = "inc-9"
      source_addresses      = ["10.9.0.0/16"]
      destination_addresses = ["10.11.0.0/16"]
      destination_ports     = ["22"]
      protocols             = ["TCP"]
    }


###dc to spoke3

		rule {
      name       = "inc-10"
      source_addresses = ["10.7.0.0/16"]
      destination_addresses = ["10.11.0.0/16"]
      destination_ports = ["*"]
      protocols = ["ICMP"]
    }
    rule {
      name                  = "inc-11"
      source_addresses      = ["10.7.0.0/16"]
      destination_addresses = ["10.11.0.0/16"]
      destination_ports     = ["80"]
      protocols             = ["TCP"]
    }
		rule {
      name                  = "inc-12"
      source_addresses      = ["10.7.0.0/16"]
      destination_addresses = ["10.11.0.0/16"]
      destination_ports     = ["22"]
      protocols             = ["TCP"]
    }
*/
  }
}







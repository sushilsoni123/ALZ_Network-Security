variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}


#####################################################################
###################### London-DC ###################################
####################################################################


variable "dc_rg_name" {
  description = "Resource group name"
  type        = string
}

variable "dc_cidr_id" {
  description = "CIDR block or identifier used in your design (confirm meaning)"
  type        = list(string)
}

variable "dc_region" {
  description = "Azure region (e.g., centralindia)"
  type        = string
}

# variable "keyword" {
#   description = "Sensitive keyword/secret (do not print)"
#   type        = string
#   sensitive   = true
# }

variable "tag" {
  description = "Tag value (or environment tag). Consider map(string) if you need multiple tags."
  type        = string
}

variable "dc_vm_subnet" {
 description= "VM Subnet name"
 type = list(string)
}

variable "dc_gateway_subnet" {
  description = "Gateway subnet CIDR (e.g., 10.0.255.0/27)"
  type        = list(string)
}

variable "dc_local_asn" {
  description = "Local ASN"
  type        = number
}

variable "dc_remote_asn" {
  description = "Remote ASN"
  type        = number
}

variable "dc_bgp_peer1" {
  description = "BGP peer IP 1"
  type        = string
}

variable "dc_bgp_peer2" {
  description = "BGP peer IP 2"
  type        = string
}

variable "dc_accepted_prefixes" {
  description = "Accepted prefixes via BGP. Use list if multiple routes are expected."
  type        = list(string)
}


variable "bgp_keyword" {
  description = "BGP shared key/password"
  type        = string
  sensitive   = true
}

# variable "vmpassword" {
#   description = "Azure subscription ID"
#   type        = string
#   sensitive = true
# }

#####################################################################
###################### Dublin-RHUB #################################
####################################################################


variable "rhub_rg_name" {
  description = "Resource group name"
  type        = string
}

variable "rhub_cidr_id" {
  description = "CIDR block or identifier used in your design (confirm meaning)"
  type        = list(string)
}

variable "rhub_region" {
  description = "Azure region (e.g., centralindia)"
  type        = string
}



variable "rhub_gateway_subnet" {
  description = "Gateway subnet CIDR (e.g., 10.0.255.0/27)"
  type        = list(string)
}

variable "rhub_local_asn" {
  description = "Local ASN"
  type        = number
}

variable "rhub_remote_asn" {
  description = "Remote ASN"
  type        = number
}

variable "rhub_bgp_peer1" {
  description = "BGP peer IP 1"
  type        = string
}

variable "rhub_bgp_peer2" {
  description = "BGP peer IP 2"
  type        = string
}

variable "rhub_accepted_prefixes" {
  description = "Accepted prefixes via BGP. Use list if multiple routes are expected."
  type        = list(string)
}
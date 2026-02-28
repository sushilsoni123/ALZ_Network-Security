output "dc_resource_group_name" {
  value = azurerm_resource_group.dc_rg.name
}

output "dc_vnet_id" {
  value = azurerm_virtual_network.dc_vnet.id
}

output "dc_gateway_public_ip1" {
  value = azurerm_public_ip.dc_pip1.ip_address
}

output "dc_gateway_public_ip2" {
  value = azurerm_public_ip.dc_pip2.ip_address
}


output "rhub_resource_group_name" {
  value = azurerm_resource_group.rhub_rg.name
}

output "rhub_vnet_id" {
  value = azurerm_virtual_network.rhub_vnet.id
}

output "rhub_gateway_public_ip1" {
  value = azurerm_public_ip.rhub_pip1.ip_address
}

output "rhub_gateway_public_ip2" {
  value = azurerm_public_ip.rhub_pip2.ip_address
}
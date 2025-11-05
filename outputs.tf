output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "cluster_name" {
  value = module.aks.aks_name
}

module "aks" {
  source  = "Azure/aks/azurerm"
  version = "11.0.0"

  prefix               = var.prefix
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  kubernetes_version   = var.kubernetes_version
  orchestrator_version = var.kubernetes_version
  network_plugin       = var.network_plugin

  depends_on = [
    azurerm_resource_group.rg
  ]
}

module "aks" {
  source  = "Azure/aks/azurerm"
  version = "11.0.0"

  prefix               = var.prefix
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  kubernetes_version   = var.kubernetes_version
  orchestrator_version = var.kubernetes_version
  network_plugin       = var.network_plugin
  public_ssh_key       = var.public_ssh_key

  sku_tier = "Standard"

  # Required for Azure Workload Identity (ExternalDNS auth)
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  # Node pool scaling configuration
  agents_count         = var.auto_scaling_enabled ? null : 2
  auto_scaling_enabled = var.auto_scaling_enabled
  agents_min_count     = var.agents_min_count
  agents_max_count     = var.agents_max_count

  depends_on = [
    azurerm_resource_group.rg
  ]
}

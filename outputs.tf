output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "cluster_name" {
  value = module.aks.aks_name
}

output "external_dns_managed_identity_client_id" {
  description = "Client ID of the user-assigned managed identity for ExternalDNS. Use this to annotate the ServiceAccount."
  value       = azurerm_user_assigned_identity.external_dns.client_id
}

output "external_dns_managed_identity_principal_id" {
  description = "Object (principal) ID of the managed identity (useful for role assignment checks)."
  value       = azurerm_user_assigned_identity.external_dns.principal_id
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster (used by workload identity)."
  value       = module.aks.oidc_issuer_url
}

output "external_dns_zone_name_servers" {
  description = "Name servers of the created public DNS zone (empty for private zones). Use these for delegation at your registrar or parent zone."
  value       = azurerm_dns_zone.public.name_servers
}

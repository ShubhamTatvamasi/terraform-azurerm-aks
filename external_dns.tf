# User-assigned managed identity for ExternalDNS
resource "azurerm_user_assigned_identity" "external_dns" {
  name                = "${var.prefix}-externaldns-mi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Grant permissions to the DNS zone
resource "azurerm_role_assignment" "external_dns_zone" {
  scope                = azurerm_dns_zone.public.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.external_dns.principal_id
}

# Reader on the DNS resource group (recommended by docs)
resource "azurerm_role_assignment" "external_dns_dnsrg_reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.external_dns.principal_id
}

# Federated identity credential binding the MI to the ExternalDNS KSA via OIDC
resource "azurerm_federated_identity_credential" "external_dns_fic" {
  name                = "${var.prefix}-externaldns-fic"
  resource_group_name = azurerm_user_assigned_identity.external_dns.resource_group_name
  parent_id           = azurerm_user_assigned_identity.external_dns.id

  audience = ["api://AzureADTokenExchange"]
  issuer   = module.aks.oidc_issuer_url
  subject  = "system:serviceaccount:${var.external_dns_namespace}:${var.external_dns_service_account_name}"
}

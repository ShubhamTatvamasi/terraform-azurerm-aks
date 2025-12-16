resource "azurerm_dns_zone" "public" {
  name                = var.external_dns_zone_name
  resource_group_name = azurerm_resource_group.rg.name
}

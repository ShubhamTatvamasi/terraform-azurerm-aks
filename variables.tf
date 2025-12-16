variable "prefix" {
  description = "Prefix for all resources."
  type        = string
  default     = "demo"
}

variable "location" {
  description = "The Azure region to deploy resources into."
  type        = string
  default     = "Central India"
}

variable "subscription_id" {
  description = "The subscription ID to deploy resources into."
  type        = string
}

variable "kubernetes_version" {
  description = "The version of Kubernetes to use for the AKS cluster."
  type        = string
  default     = "1.34"
}

variable "network_plugin" {
  description = "The network plugin to use for the AKS cluster. Possible values are 'azure' or 'kubenet'."
  type        = string
  default     = "azure"
}

# ExternalDNS configuration
variable "external_dns_namespace" {
  description = "Namespace where ExternalDNS will run."
  type        = string
  default     = "external-dns"
}

variable "external_dns_service_account_name" {
  description = "ServiceAccount name used by ExternalDNS."
  type        = string
  default     = "external-dns"
}

variable "external_dns_zone_name" {
  description = "Azure DNS zone name managed by ExternalDNS (e.g., example.com)."
  type        = string
  default     = "azure.shubhamtatvamasi.com"
}

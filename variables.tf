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

variable "network_plugin_mode" {
  description = "Network plugin mode. Set to 'overlay' for Azure CNI overlay mode."
  type        = string
  default     = "overlay"

  validation {
    condition     = var.network_plugin_mode == null || var.network_plugin_mode == "overlay"
    error_message = "network_plugin_mode must be 'overlay' or null. Use 'overlay' for Azure CNI overlay mode."
  }
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

variable "public_ssh_key" {
  description = "A custom ssh public key to control access to the AKS nodes."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

# Autoscaling configuration
variable "auto_scaling_enabled" {
  description = "Enable autoscaling for the node pool."
  type        = bool
  default     = true
}

variable "agents_min_count" {
  description = "Minimum number of nodes in the node pool."
  type        = number
  default     = 1
}

variable "agents_max_count" {
  description = "Maximum number of nodes in the node pool."
  type        = number
  default     = 2
}

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
  default     = "1.33"
}

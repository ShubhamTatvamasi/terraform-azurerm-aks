#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
EXTERNAL_DNS_NAMESPACE="external-dns"
EXTERNAL_DNS_SERVICE_ACCOUNT="external-dns"
EXTERNAL_DNS_ZONE_RG="demo-rg"
EXTERNAL_DNS_ZONE_NAME="azure.shubhamtatvamasi.com"
CLUSTER_RG="demo-rg"
CLUSTER_NAME="demo-aks"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace)
      EXTERNAL_DNS_NAMESPACE="$2"
      shift 2
      ;;
    --service-account)
      EXTERNAL_DNS_SERVICE_ACCOUNT="$2"
      shift 2
      ;;
    --zone-rg)
      EXTERNAL_DNS_ZONE_RG="$2"
      shift 2
      ;;
    --zone-name)
      EXTERNAL_DNS_ZONE_NAME="$2"
      shift 2
      ;;
    --cluster-rg)
      CLUSTER_RG="$2"
      shift 2
      ;;
    --cluster-name)
      CLUSTER_NAME="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${YELLOW}=== ExternalDNS Deployment Script ===${NC}"
echo -e "Namespace: $EXTERNAL_DNS_NAMESPACE"
echo -e "Service Account: $EXTERNAL_DNS_SERVICE_ACCOUNT"
echo -e "DNS Zone RG: $EXTERNAL_DNS_ZONE_RG"
echo -e "DNS Zone Name: $EXTERNAL_DNS_ZONE_NAME"
echo -e "Cluster RG: $CLUSTER_RG"
echo -e "Cluster Name: $CLUSTER_NAME"
echo ""

# Step 1: Set Terraform variables
echo -e "${YELLOW}[1/6] Setting Terraform variables...${NC}"
export TF_VAR_external_dns_zone_resource_group="$EXTERNAL_DNS_ZONE_RG"
export TF_VAR_external_dns_zone_name="$EXTERNAL_DNS_ZONE_NAME"
export TF_VAR_external_dns_namespace="$EXTERNAL_DNS_NAMESPACE"
export TF_VAR_external_dns_service_account_name="$EXTERNAL_DNS_SERVICE_ACCOUNT"
echo -e "${GREEN}✓ Terraform variables set${NC}\n"

# Step 2: Apply Terraform
echo -e "${YELLOW}[2/6] Applying Terraform to create Managed Identity and DNS zone...${NC}"
if terraform apply -auto-approve > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Terraform applied successfully${NC}\n"
else
  echo -e "${RED}✗ Terraform apply failed. Check errors above.${NC}"
  exit 1
fi

# Step 3: Get Managed Identity Client ID
echo -e "${YELLOW}[3/6] Retrieving Managed Identity Client ID...${NC}"
CLIENT_ID=$(terraform output -raw external_dns_managed_identity_client_id)
echo -e "${GREEN}✓ Client ID: $CLIENT_ID${NC}\n"

# Step 4: Create namespace and Azure config secret
echo -e "${YELLOW}[4/6] Creating namespace and Azure config secret...${NC}"
kubectl create namespace "$EXTERNAL_DNS_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Delete old ServiceAccount if it exists
kubectl delete serviceaccount "$EXTERNAL_DNS_SERVICE_ACCOUNT" -n "$EXTERNAL_DNS_NAMESPACE" --ignore-not-found > /dev/null 2>&1

# Create azure.json
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
cat > /tmp/azure.json <<EOF
{
  "subscriptionId": "$SUBSCRIPTION_ID",
  "resourceGroup": "$EXTERNAL_DNS_ZONE_RG",
  "useWorkloadIdentityExtension": true
}
EOF

# Create secret
kubectl -n "$EXTERNAL_DNS_NAMESPACE" create secret generic azure-config-file --from-file /tmp/azure.json --dry-run=client -o yaml | kubectl apply -f -
rm /tmp/azure.json
echo -e "${GREEN}✓ Namespace and secrets created${NC}\n"

# Step 5: Add Helm repository
echo -e "${YELLOW}[5/6] Adding ExternalDNS Helm repository...${NC}"
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/ > /dev/null 2>&1
helm repo update > /dev/null 2>&1
echo -e "${GREEN}✓ Helm repo added and updated${NC}\n"

# Step 6: Install ExternalDNS
echo -e "${YELLOW}[6/6] Installing ExternalDNS via Helm...${NC}"
cat > /tmp/external-dns-values.yaml <<EOF
fullnameOverride: external-dns
provider:
  name: azure
serviceAccount:
  name: $EXTERNAL_DNS_SERVICE_ACCOUNT
  annotations:
    azure.workload.identity/client-id: "$CLIENT_ID"
podLabels:
  azure.workload.identity/use: "true"
extraVolumes:
  - name: azure-config-file
    secret:
      secretName: azure-config-file
extraVolumeMounts:
  - name: azure-config-file
    mountPath: /etc/kubernetes
    readOnly: true
txtPrefix: externaldns-
sources:
  - service
  - ingress
domainFilters:
  - $EXTERNAL_DNS_ZONE_NAME
EOF

helm upgrade --install external-dns external-dns/external-dns \
  -n "$EXTERNAL_DNS_NAMESPACE" \
  -f /tmp/external-dns-values.yaml > /dev/null 2>&1

rm /tmp/external-dns-values.yaml
echo -e "${GREEN}✓ ExternalDNS installed${NC}\n"

# Final status
echo -e "${GREEN}=== ExternalDNS Deployment Complete ===${NC}"
echo ""
echo "Verify deployment:"
echo "  kubectl get pods -n $EXTERNAL_DNS_NAMESPACE"
echo "  kubectl logs -n $EXTERNAL_DNS_NAMESPACE -l app.kubernetes.io/name=external-dns --tail=50"
echo ""
echo "DNS Zone: $EXTERNAL_DNS_ZONE_NAME"
echo "Namespace: $EXTERNAL_DNS_NAMESPACE"

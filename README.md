# terraform-azurerm-aks

List account subscriptions:
```bash
az account list -o table
```

Update **subscription_id** in `terraform.tfvars` file:
```bash
cat > terraform.tfvars << EOF
subscription_id = $(az account list --query "[0].id")
EOF
```

---

Initalize Terraform:
```bash
terraform init -upgrade
```

Create the cluster:
```bash
terraform apply -auto-approve
```

Destroy the cluster:
```bash
terraform destroy -auto-approve
```

---

Set kubectl context to the new AKS cluster:
```bash
az aks get-credentials \
  --resource-group demo-rg \
  --name demo-aks \
  --overwrite-existing
```

---

## ExternalDNS on AKS (Azure DNS + Workload Identity)

- Prereqs: set these variables (adjust for your zone):

```bash
export TF_VAR_external_dns_zone_resource_group="demo-rg"            # or your preferred RG
export TF_VAR_external_dns_zone_name="azure.shubhamtatvamasi.com"   # your domain
export TF_VAR_external_dns_namespace="external-dns"
export TF_VAR_external_dns_service_account_name="external-dns"
```

- Apply Terraform again to create the Managed Identity, role assignments, and federated identity:

```bash
terraform apply -auto-approve
```

- Get the managed identity Client ID (output):

```bash
terraform output -raw external_dns_managed_identity_client_id
```

- Create the ExternalDNS Azure config secret (workload identity mode):

```bash
# Delete the ServiceAccount if manually created earlier (to let Helm manage it)
kubectl delete serviceaccount external-dns -n "$TF_VAR_external_dns_namespace" --ignore-not-found

cat <<EOF > azure.json
{
  "subscriptionId": "$(az account show --query id -o tsv)",
  "resourceGroup": "${TF_VAR_external_dns_zone_resource_group}",
  "useWorkloadIdentityExtension": true
}
EOF
kubectl -n "$TF_VAR_external_dns_namespace" create secret generic azure-config-file --from-file azure.json --dry-run=client -o yaml | kubectl apply -f -
rm azure.json
```

- Install ExternalDNS (helm) using workload identity. Example using kubernetes-sigs chart:

```bash
kubectl create namespace "$TF_VAR_external_dns_namespace" || true

helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update

# Create a temporary values file with workload identity settings
cat > /tmp/external-dns-values.yaml <<EOF
fullnameOverride: external-dns
provider:
  name: azure
serviceAccount:
  name: $TF_VAR_external_dns_service_account_name
  annotations:
    azure.workload.identity/client-id: "$(terraform output -raw external_dns_managed_identity_client_id)"
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
  - $TF_VAR_external_dns_zone_name
EOF

helm upgrade --install external-dns external-dns/external-dns \
  -n "$TF_VAR_external_dns_namespace" \
  -f /tmp/external-dns-values.yaml

rm /tmp/external-dns-values.yaml
```

Notes:
- If using Private DNS, set `TF_VAR_external_dns_use_private_dns=true` before `terraform apply` and point ExternalDNS to your private zones.
- ExternalDNS needs your Ingress controller to publish its Service name: add `--publish-service=<namespace>/<svc-name>` to nginx ingress args.
 - The DNS zone is created by Terraform in the specified resource group.
 - After the zone is created, delegate its name servers from your registrar or parent zone so records resolve on the internet.

---

## Troubleshooting LoadBalancer access

- If your ingress Service has annotation `service.beta.kubernetes.io/azure-load-balancer-internal: "true"`, the IP will be internal (10.x) and not reachable from the internet. Remove that annotation (or set it to `false`) for a public IP.
- Ensure an `EXTERNAL-IP` is allocated:

```bash
kubectl get svc -A | grep LoadBalancer
```

- For public access: confirm the Service shows a public IP and DNS resolves to it. If unreachable:
  - Check NSG rules on the nodepool subnet allow inbound 80/443.
  - If you pre-allocate a static public IP, set it via helm (e.g., `controller.service.loadBalancerIP`) and ensure it exists in the AKS node resource group (MC_...).
  - Private clusters or UDRs with next-hop firewalls can block traffic; verify routing.


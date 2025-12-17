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

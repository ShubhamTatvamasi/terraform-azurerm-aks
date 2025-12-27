# Cert-Manager Setup for AKS

This guide walks through installing and configuring cert-manager for automatic SSL/TLS certificate management in your AKS cluster using Let's Encrypt.

## Overview

Cert-manager is a Kubernetes-native certificate management controller that:
- Automatically issues and renews SSL/TLS certificates
- Integrates with Let's Encrypt for free certificates
- Works seamlessly with ExternalDNS for DNS-01 ACME challenges
- Manages certificate lifecycle across your cluster

## Prerequisites

- AKS cluster deployed with ExternalDNS
- `kubectl` configured to access your cluster
- Helm installed locally
- An Azure DNS zone for your domain

## Installation

### 1. Add the Jetstack Helm Repository

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

### 2. Install Cert-Manager

Install cert-manager with custom resource definitions (CRDs) enabled:

```bash
helm upgrade -i cert-manager jetstack/cert-manager \
  --create-namespace \
  --namespace cert-manager \
  --set crds.enabled=true \
  --set global.leaderElection.namespace=cert-manager
```

### 3. Verify Installation

Wait for all cert-manager pods to be running:

```bash
kubectl rollout status deployment/cert-manager -n cert-manager
kubectl rollout status deployment/cert-manager-webhook -n cert-manager
```

Check that CRDs are installed:

```bash
kubectl get crds | grep cert-manager
```

## Configuration

### Create a ClusterIssuer for Let's Encrypt

This ClusterIssuer will handle automatic certificate issuance using HTTP-01 validation:

```bash
kubectl apply -f - << 'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
EOF
```

**Optional: Staging ClusterIssuer** (for testing, has higher rate limits):

```bash
kubectl apply -f - << 'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-staging-key
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
EOF
```

## Using Certificates in Ingress

Annotate your Ingress resources with cert-manager to automatically provision and renew certificates:

```bash
kubectl apply -f - << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    external-dns.alpha.kubernetes.io/hostname: azure.shubhamtatvamasi.com
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - azure.shubhamtatvamasi.com
    secretName: example-tls-cert
  rules:
  - host: azure.shubhamtatvamasi.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
EOF
```

## Verification

### Check Certificate Status

```bash
# List all certificates in the cluster
kubectl get certificate -A

# Get detailed info about a specific certificate
kubectl describe certificate example-tls-cert -n default
```

### Check Certificate Secret

```bash
# View the TLS secret created by cert-manager
kubectl get secret example-tls-cert -o yaml
```

### Monitor Cert-Manager Logs

```bash
# View cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager -f

# View webhook logs (for ACME challenges)
kubectl logs -n cert-manager deployment/cert-manager-webhook -f
```

## Troubleshooting

### Certificate stuck in "Pending" state

1. Check ClusterIssuer status:
```bash
kubectl describe clusterissuer letsencrypt-prod
```

2. Check CertificateRequest status:
```bash
kubectl describe certificaterequest -n default
```

3. Check cert-manager logs:
```bash
kubectl logs -n cert-manager deployment/cert-manager
kubectl logs -n cert-manager deployment/cert-manager-webhook
```

### ACME Challenge Failures

Ensure your Ingress is correctly configured:
- Hostname must be publicly resolvable via DNS
- Port 80 must be accessible from the internet
- ExternalDNS must have created the DNS record

Verify DNS propagation:
```bash
nslookup azure.shubhamtatvamasi.com
```

### Rate Limiting

If you hit Let's Encrypt rate limits:
- Use the staging ClusterIssuer for testing
- Wait ~1 hour before retrying
- Check your certificate renewal frequency

## Best Practices

1. **Use Staging for Testing**: Test with `letsencrypt-staging` before switching to `letsencrypt-prod`
2. **Email Notifications**: Add a valid email to the ClusterIssuer for renewal notifications
3. **Monitor Expiration**: Set up alerts for certificates nearing expiration
4. **Multiple Domains**: Use Subject Alternative Names (SANs) for multiple domains
5. **Backup Secrets**: Regularly backup certificate secrets in case of loss

## Advanced Configuration

### Multiple Domains (SAN)

```yaml
tls:
- hosts:
  - azure.shubhamtatvamasi.com
  - api.azure.shubhamtatvamasi.com
  - admin.azure.shubhamtatvamasi.com
  secretName: multi-domain-cert
```

### Wildcard Certificates

Requires DNS-01 challenge (Azure DNS integration needed):

```yaml
cert-manager.io/cluster-issuer: letsencrypt-dns
spec:
  tls:
  - hosts:
    - '*.azure.shubhamtatvamasi.com'
    secretName: wildcard-cert
```

## References

- [Cert-Manager Documentation](https://cert-manager.io/docs/)
- [Let's Encrypt ACME Challenges](https://letsencrypt.org/how-it-works/)
- [Kubernetes Ingress TLS](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls)

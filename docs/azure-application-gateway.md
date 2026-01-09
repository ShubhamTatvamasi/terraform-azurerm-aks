
## Azure Application Gateway Ingress Controller (AGIC)

Set the Azure Application Gateway Ingress Controller as the default IngressClass:
```bash
kubectl annotate ingressclass azure-application-gateway \
  ingressclass.kubernetes.io/is-default-class="true"
```

## ClusterIssuer for Let's Encrypt
```bash
kubectl apply -f - << 'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - http01:
        ingress:
          ingressClassName: azure-application-gateway
EOF
```

## Using Certificates in Ingress
```yaml
kubectl apply -f - << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    external-dns.alpha.kubernetes.io/hostname: azure.shubhamtatvamasi.com
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: azure-application-gateway
  tls:
  - hosts:
    - azure.shubhamtatvamasi.com
    secretName: azure-shubhamtatvamasi-tls-cert
  rules:
  - host: azure.shubhamtatvamasi.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
EOF
```

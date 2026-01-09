# Ingress

## Add Ingress-Nginx Helm Repository
Add the official nginx ingress controller Helm repository and update local cache.

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

## Install Ingress-Nginx Controller
Deploy the nginx ingress controller with optimized configuration:
- `controller.replicaCount=2`: Deploy 2 replicas for high availability
- `controller.ingressClassResource.default=true`: Set as default ingress class
- `nodeSelector`: Run on Linux nodes only
- `externalTrafficPolicy=Local`: Preserve client source IP

```bash
helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace ingress-nginx \
  --set controller.ingressClassResource.default=true \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.service.externalTrafficPolicy=Local
```

---

## Azure Application Gateway Ingress Controller (AGIC)

Set the Azure Application Gateway Ingress Controller as the default IngressClass:
```bash
kubectl annotate ingressclass azure-application-gateway \
  ingressclass.kubernetes.io/is-default-class="true"
```

---

## Test Ingress Controller

## Create Test Nginx Application
Deploy a simple nginx application for testing the ingress controller.

```bash
kubectl create deployment nginx --image=nginx:alpine
kubectl expose deployment nginx --port=80 --name=nginx
```


## Create Ingress Resource
Create an Ingress resource that:
- Routes traffic for `azure.shubhamtatvamasi.com` to the nginx service
- Annotated for ExternalDNS to automatically manage DNS records
- Uses the default nginx ingress class

```yaml
kubectl apply -f - << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    external-dns.alpha.kubernetes.io/hostname: azure.shubhamtatvamasi.com
spec:
  ingressClassName: azure-application-gateway
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

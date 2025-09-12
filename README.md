# Setup in Kubernetes

## Install ArgoCD
```sh
git clone https://github.com/container8/keycloak-argocd.git
cd keycloak-argocd/argocd-bootstrap
helm -n argocd upgrade --install argocd ./bootstrap/base/ \
  -f ./bootstrap/base/values.yaml \
  --create-namespace
kubectl apply -k bootstrap/overlays/default/
```

Get ArgoCD admin password:

```sh
kubectl -n argocd get secrets argocd-initial-admin-secret -o json | jq '.data.password' -r | base64 -d
```

# Keycloak Terraform Provider
## Keycloak Configuration
```sh
git clone https://github.com/container8/keycloak-terraform.git
cd keycloak-sso/keycloak-config
terraform init
terraform plan
terraform apply
```

---

# Keycloak / ArgoCD Integration

```sh
cd argocd/argocd-bootstrap
git fetch
git checkout argocd-oidc-config
helm -n argocd upgrade --install argocd ./bootstrap/base/ \
  -f ./bootstrap/base/values.yaml \
  -f ./bootstrap/base/secrets.yaml \
  --create-namespace
kubectl apply -k bootstrap/overlays/default/
```

---

# Keycloak / Grafana Integration

```sh
cd argocd-bootstrap
git fetch
git checkout kube-prometheus-stack
kubectl apply -k bootstrap/overlays/default/
```

# OAuth2 Proxy Example

```sh
cd argocd-bootstrap
git fetch
git checkout oauth2-proxy
kubectl apply -k bootstrap/overlays/default/
```

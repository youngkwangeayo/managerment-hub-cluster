```bash

# 베포
helm upgrade --install target-cluster-setup helm-charts/argocd-manager/target-cluster-setup/ \
    -n argocd-manager \
    --create-namespace \
    -f helm-charts/argocd-manager/target-cluster-setup/values.yaml



# Bearer Token 추출 (디코딩)
kubectl get secret argocd-manager-token \
  -n argocd-manager \
  -o jsonpath='{.data.token}' | base64 --decode


# CA Certificate 추출 (디코딩 안 함!)
kubectl -n argocd-manager get secret argocd-manager-token -o jsonpath='{.data.ca\.crt}'


# k8sAPI endPoint
kubectl config view --minify --output jsonpath='{.clusters[0].cluster.server}'

```
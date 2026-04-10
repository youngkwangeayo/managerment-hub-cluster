
<!-- https://argo-cd.readthedocs.io/en/stable/getting_started/ -->
<!-- https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/ -->
<!-- ingress 문서 참조 https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/ -->

<!-- 비트버킷 ssh 적용 -->
<!-- argocd_key.pub  -->

```bash
kubectl create namespace argocd


kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl get all -n argocd

```


```bash
brew install argocd
```

QaeNext77pay77

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d


# 아르고 cli 로그인
argocd login localhost:8080 --insecure


# pw 변경
argocd account update-password


```



```bash
확인
kubectl get application -n argocd 

kubectl get application app-test1 -n argocd -o jsonpath='{.spec.syncPolicy}' 2>&1
```
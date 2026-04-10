
<!-- https://argo-cd.readthedocs.io/en/stable/getting_started/ -->
<!-- https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/ -->
<!-- ingress 문서 참조 https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/ -->

<!-- 비트버킷 ssh 적용 -->
<!-- argocd_key.pub  -->


```bash
brew install argocd
```

```bash
kubectl create namespace argocd

kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl get all -n argocd
```
## 초기비번 ui 에서 할것


```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

```

# ------------------------------------------------------------------------------------------------------------------------------

```bash
# 초기 허브 베포 
kubectl apply -f argocd/bootstrap/init-hub-repo-secret.yaml
kubectl apply -f argocd/bootstrap/root-hub-setup.yaml


# oauth 재구동
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout restart deploy argocd-dex-server -n argocd
```

# ------------------------------------------------------------------------------------------------------------------------------

```bash
# 루트앱 베포

kubectl apply -f argocd/clusters/{솔루션네임}/root-app-{환경}.yaml
```



```bash
확인
kubectl get application -n argocd 

kubectl get application app-test1 -n argocd -o jsonpath='{.spec.syncPolicy}' 2>&1
```


# ------------------------------------------------------------------------------------------------------------------------------

```bash
디버깅
kubectl describe application hub-setup-app -n argocd
```

# ------------------------------------------------------------------------------------------------------------------------------
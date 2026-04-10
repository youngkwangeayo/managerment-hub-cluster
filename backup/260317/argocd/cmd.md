
<!-- https://argo-cd.readthedocs.io/en/stable/getting_started/ -->
<!-- https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/ -->

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

```bash
# 외부노출시 서비스유형을 로드밸런서로 변경
# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
# kubectl get svc argocd-server -n argocd -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'

# ingress 문서 참조 https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/
```

QaeNext77pay77

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443


# 초기 pw 확인. admin계정으로 평문으로 저장되어있음. 이후 argocd-initial-admin-secret 삭제.
kubectl get secrets -n argocd argocd-initial-admin-secret -o yaml
argocd admin initial-password -n argocd


# 아르고 cli 로그인
argocd login localhost:8080 --insecure


# pw 변경
argocd account update-password

argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default
```






```bash
확인
kubectl get application -n argocd 

kubectl get application app-test1 -n argocd -o jsonpath='{.spec.syncPolicy}' 2>&1
```
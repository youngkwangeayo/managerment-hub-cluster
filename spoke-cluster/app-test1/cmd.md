
```bash
helm upgrade --install app-test1 helm-charts/app-test1/ \
     -n {ns} \
     -f helm-charts/app-test1/values.yaml \
     -f helm-charts/app-test1/values-dev.yaml
```
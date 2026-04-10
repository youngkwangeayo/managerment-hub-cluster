```bash
helm upgrade --install infra helm-charts/infra-system/infra/ \
     -n infra-system \
     -f helm-charts/infra-system/infra/values.yaml \
     -f helm-charts/infra-system/infra/values-prod.yaml 

```
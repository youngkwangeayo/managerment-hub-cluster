
```bash

# 개발
helm upgrade --install infra-spoke helm-charts/infra-system/infra-spoke/ \
     -n dev-signage \
     -f helm-charts/infra-system/infra-spoke/values.yaml \
     -f helm-charts/infra-system/infra-spoke/values-dev.yaml 


# 운영
helm upgrade --install infra-spoke helm-charts/infra-system/infra-spoke/ \
     -n prod-signage \
     -f helm-charts/infra-system/infra-spoke/values.yaml \
     -f helm-charts/infra-system/infra-spoke/values-prod.yaml      
```
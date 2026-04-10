# 개발자 가이드 — Management HUB

이 문서는 개발자가 새로운 헬름차트를 ArgoCD 배포 파이프라인에 등록하는 방법을 설명합니다.

---

## 개요

Management HUB 는 App of Apps 패턴으로 동작합니다.
개발자가 할 일은 **자신의 솔루션 클러스터에 해당하는 values 파일에 앱 항목을 추가**하는 것뿐입니다.

```
argocd/clusters/{클러스터}/apps/
├── values.yaml          # 공통 설정 (수정 불필요)
├── values-dev.yaml      # ← dev 배포할 앱 목록
└── values-prod.yaml     # ← prod 배포할 앱 목록
```

---

## 앱 추가 방법

### 1. 파일 위치 확인

자신의 솔루션 클러스터에 해당하는 values 파일을 엽니다.

| 솔루션 | 파일 경로 |
|---|---|
| cms | `argocd/clusters/cms/apps/values-{env}.yaml` |
| aiagent | `argocd/clusters/aiagent/apps/values-{env}.yaml` |

### 2. apps 섹션에 항목 추가

```yaml
appPrefix: dev-cms-   # 건드리지 않습니다

apps:
  # 기존 앱
  - name: cms
    path: helm-charts/cms
    namespace: dev-cms
    valueFiles:
      - values.yaml
      - values-dev.yaml

  # 새로 추가할 앱 ↓
  - name: <<APP_NAME>>              # 헬름차트 이름 (예: cms-cron)
    path: helm-charts/<<APP_NAME>>  # 솔루션 레포 내 헬름차트 경로
    namespace: dev-<<CLUSTER>>      # 배포될 네임스페이스 (예: dev-cms)
    valueFiles:
      - values.yaml
      - values-dev.yaml             # 환경에 맞는 values 파일
```

**실제 예시 (cms-cron 추가):**

```yaml
apps:
  - name: cms
    path: helm-charts/cms
    namespace: dev-cms
    valueFiles:
      - values.yaml
      - values-dev.yaml
  - name: cms-cron           # ← 추가
    path: helm-charts/cms-cron
    namespace: dev-cms
    valueFiles:
      - values.yaml
      - values-dev.yaml
```

### 3. PR 및 배포

> **브랜치 전략:** 이 레포의 `main` 브랜치가 GitOps 의 기준입니다. `dev` 브랜치는 소스 코드 개발용이며 ArgoCD 와 무관합니다.

- **dev** → `main` 브랜치에 머지하면 ArgoCD 가 자동 Sync
- **prod** → `main` 브랜치에 머지하면 ArgoCD UI 에서 수동 Sync

---

## 앱 이름 규칙

ArgoCD 에 등록되는 앱의 풀네임은 자동으로 prefix 가 붙습니다.

```
{appPrefix}{name}
예: dev-cms- + cms-cron = dev-cms-cms-cron
```

ArgoCD UI 또는 `make describe-app` 에서 이 이름으로 조회할 수 있습니다.

---

## 주의사항

- `values.yaml` (공통), `appPrefix`, `cascadeDelete`, `targetRevision` 은 수정하지 않습니다.
- 헬름차트 경로(`path`)는 솔루션 레포 기준 상대경로입니다.
- prod 추가 시 `values-prod.yaml` 에도 동일하게 추가해야 합니다.

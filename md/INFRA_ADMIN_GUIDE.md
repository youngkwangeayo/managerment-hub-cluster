# 인프라 관리자 가이드 — Management HUB

이 문서는 Management HUB 에 새로운 솔루션/클러스터를 추가하거나 사용자를 관리하는 방법을 설명합니다.

---

## 브랜치 전략

| 브랜치 | 용도 |
|---|---|
| `main` | **IaC 운영 브랜치** — ArgoCD 가 이 브랜치를 바라봅니다. 모든 인프라 변경은 `main` 에 머지해야 반영됩니다. |
| `dev` | 소스 코드 개발 브랜치 — 인프라 변경과 무관합니다. |

> ArgoCD 의 모든 `targetRevision` 은 `main` 을 기준으로 동작합니다.

---

## 목차

- [1. 사용자 권한 추가](#1-사용자-권한-추가)
- [2. 새 솔루션 클러스터 연결](#2-새-솔루션-클러스터-연결)
- [3. 새 솔루션 App of Apps 추가](#3-새-솔루션-app-of-apps-추가)

---

## 1. 사용자 권한 추가

**파일:** `argocd/hub-setup/templates/0-rbac-configmap.yaml`

`policy.csv` 섹션에 한 줄 추가합니다.

```yaml
policy.csv: |
  g, hugo@n*****.co.kr, role:admin
  g, philip@n*****.co.kr, role:admin
  g, 새유저@n*****.co.kr, role:admin      # ← 추가
```

**역할 종류:**
- `role:admin` — 전체 읽기/쓰기/배포 권한
- `role:readonly` — 읽기 전용 (기본값)

PR → main 머지 후 ArgoCD 가 자동 Sync 합니다.

---

## 2. 새 솔루션 클러스터 연결

새로운 솔루션 클러스터(스포크)를 허브에 연결할 때 3가지를 추가합니다.

**파일:** `argocd/hub-setup/values.yaml`

### 2-1. 스포크 클러스터 연결 정보 조회

스포크 클러스터에 컨텍스트를 맞춘 뒤 실행합니다.

```bash
# 스포크 클러스터에 argocd-manager 설치 후 연결 정보 조회
make setup-spoke    # 최초 설치 + 정보 출력
make get-spoke-info # 이미 설치된 경우 정보만 출력
```

출력된 `Bearer Token`, `CA Certificate`, `API Endpoint` 를 아래에 채워 넣습니다.

### 2-2. repositories 섹션에 추가

```yaml
repositories:
  - name: <<SOLUTION>>-k8s          # 예: new-solution-k8s
    url: git@bitbucket.org:*******/<<SOLUTION>>-k8s.git
    sshPrivateKey: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      <<SSH_PRIVATE_KEY>>
      -----END OPENSSH PRIVATE KEY-----
```

### 2-3. projects 섹션에 추가

```yaml
projects:
  - name: dev-<<SOLUTION>>-k8s-project   # 예: dev-new-solution-k8s-project
    description: "A Service Development Environment"
    sourceRepos:
      - "git@bitbucket.org:*******/<<SOLUTION>>-k8s.git"
    destinations:
      - server: "https://<<CLUSTER_API_SERVER>>"
        namespace: "*"
```

### 2-4. clusters 섹션에 추가

```yaml
clusters:
  - name: dev-<<SOLUTION>>-k8s-cluster   # 예: dev-new-solution-k8s-cluster
    server: "https://<<CLUSTER_API_SERVER>>"     # get-spoke-info 의 API Endpoint
    bearerToken: "<<BEARER_TOKEN>>"              # get-spoke-info 의 Bearer Token
    tlsClientConfig:
      insecure: false
      caData: "<<CA_DATA>>"                      # get-spoke-info 의 CA Certificate
```

PR → main 머지 후 ArgoCD 가 자동 Sync 합니다.

---

## 3. 새 솔루션 App of Apps 추가

`template/app-of-apps/` 를 복사해서 `argocd/clusters/` 아래에 새 디렉토리를 만듭니다.

### 3-1. 템플릿 복사

```bash
cp -r template/app-of-apps/ argocd/clusters/<<CLUSTER>>/
# 예: cp -r template/app-of-apps/ argocd/clusters/new-solution/
```

### 3-2. 수정할 파일 목록

| 파일 | 수정 내용 |
|---|---|
| `root-app-dev.yaml` | `name`, `path` 의 `<<CLUSTER>>` 교체 |
| `root-app-prod.yaml` | `name`, `path` 의 `<<CLUSTER>>` 교체 |
| `apps/Chart.yaml` | `name` 의 `<<CLUSTER>>` 교체 |
| `apps/values.yaml` | `spec.destination.server`, `repoURL`, `project` 교체 |
| `apps/values-dev.yaml` | `appPrefix`, `apps` 항목 작성 |
| `apps/values-prod.yaml` | `appPrefix`, `apps` 항목 작성 |

### 3-3. 루트 앱 배포

```bash
# 허브 클러스터 컨텍스트로 전환 후
make deploy-root-app ENV=dev CLUSTER=<<CLUSTER>>
make deploy-root-app ENV=prod CLUSTER=<<CLUSTER>>
```

ArgoCD UI 에서 `dev-<<CLUSTER>>-root-apps` 앱이 생성되고, 하위 앱들이 자동 배포됩니다.

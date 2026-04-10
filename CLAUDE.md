# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the **Management HUB Cluster** — a GitOps infrastructure repository managing Kubernetes deployments via ArgoCD using an **App-of-Apps pattern** with a **hub-and-spoke topology**.

- **Hub cluster**: Runs ArgoCD and manages all spoke clusters
- **Spoke clusters**: `cms`, `aiagent`, `elasticsearch-cluster` (solution clusters)
- **Cloud**: AWS EKS, region `ap-northeast-2`, account `365485194891`
- **GitOps source**: `main` branch only — all ArgoCD `targetRevision` points to `main`

## Common Commands

All operational tasks go through `make`. Run `make help` for a full list.

```bash
# Connect to an EKS cluster (registers kubeconfig)
make connect ENV=dev CLUSTER=cms

# Switch to a registered kubeconfig context
make use-cluster ENV=dev CLUSTER=cms

# Deploy a root app for a solution cluster
make deploy-root-app ENV=dev CLUSTER=cms
make deploy-root-app ENV=prod CLUSTER=cms

# Delete a root app (non-cascading — child resources are NOT deleted)
make delete-root-app ENV=dev CLUSTER=cms

# Restart ArgoCD auth server (after OAuth changes)
make sync-auth

# List and describe ArgoCD applications
make describe-app

# Setup spoke cluster (run from spoke cluster context)
make setup-spoke
make get-spoke-info

# Bootstrap hub cluster (one-time only — irreversible)
make bootstrap
```

**Parameters:**
- `ENV`: `dev` | `prod` | `local`
- `CLUSTER`: `mgmt-hub` | `aiagent` | `cms` | `elasticsearch-cluster`

**Prerequisites:** `kubectl`, `awscli`, `argocd`, `helm`

## Architecture

### Directory Structure

```
argocd/
├── bootstrap/              # One-time hub setup (init-hub-repo-secret, root-hub-setup)
├── hub-setup/              # Helm chart managing the hub itself (repos, projects, clusters, RBAC)
│   └── templates/
│       └── 0-rbac-configmap.yaml   # ArgoCD user permissions
└── clusters/               # Per-solution App-of-Apps configurations
    ├── cms/
    │   ├── apps/           # Helm chart listing all CMS apps
    │   │   ├── values.yaml         # Common (do not modify)
    │   │   ├── values-dev.yaml     # Dev app list
    │   │   └── values-prod.yaml    # Prod app list
    │   ├── root-app-dev.yaml
    │   └── root-app-prod.yaml
    └── aiagent/            # Same structure as cms/

helm-charts/
├── shared/                 # Shared infra (ingress, storage, HPA)
└── logging/                # Fluentbit + logging backend

template/app-of-apps/       # Template for adding new solution clusters
spoke-cluster/              # Spoke cluster setup helpers
```

### App-of-Apps Pattern

Each solution cluster has:
1. **Root app** (`root-app-{env}.yaml`) — deployed manually via `make deploy-root-app`, points ArgoCD at the `apps/` Helm chart
2. **Apps Helm chart** (`apps/`) — renders individual ArgoCD `Application` manifests from `values-{env}.yaml`

App naming convention: `{appPrefix}{name}` → e.g., `dev-cms-` + `cms-cron` = `dev-cms-cms-cron`

### Sync Policy

- **dev**: Auto-sync with prune + selfHeal (`automated: { prune: true, selfHeal: true }`)
- **prod**: Manual sync via ArgoCD UI after merging to `main`

## Developer Workflow: Adding an App

Edit `argocd/clusters/{cluster}/apps/values-{env}.yaml` and add an entry under `apps:`:

```yaml
apps:
  - name: my-service          # becomes {appPrefix}my-service in ArgoCD
    path: helm-charts/my-service   # path in the solution repo
    namespace: dev-cms
    valueFiles:
      - values.yaml
      - values-dev.yaml
```

Do **not** modify `values.yaml` (common), `appPrefix`, `cascadeDelete`, or `targetRevision`.

Merge to `main` → ArgoCD auto-syncs dev; prod requires manual sync in the UI.

## Admin Workflow: Adding a New Solution Cluster

1. Copy template: `cp -r template/app-of-apps/ argocd/clusters/{new-cluster}/`
2. Replace `<<CLUSTER>>` placeholders in `root-app-*.yaml`, `apps/Chart.yaml`, `apps/values*.yaml`
3. Add cluster connection info to `argocd/hub-setup/values.yaml` (repositories, projects, clusters sections) using output from `make get-spoke-info`
4. Add user permissions in `argocd/hub-setup/templates/0-rbac-configmap.yaml`
5. Deploy: `make deploy-root-app ENV=dev CLUSTER={new-cluster}`

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | **IaC operations branch** — ArgoCD source of truth |
| `dev`  | Source code development — unrelated to ArgoCD |

All infrastructure changes must be merged to `main` to take effect.

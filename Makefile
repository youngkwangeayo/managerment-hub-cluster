
# ============================================================

# --- 파라미터 (make 실행 시 오버라이드) ---
ENV ?=
CLUSTER ?=
TAG ?=
CLUSTER ?=

# --- 상수 ---
AWS_REGION     := ap-northeast-2
AWS_ACCOUNT_ID := 365485194891

ALLOWED_ENVS    := dev prod local
ALLOWED_CLUSTER  := mgmt-hub aiagent cms signage elasticsearch-cluster


.PHONY: help install-guide connect validate use-cluster bootstrap sync-auth describe-app setup-spoke get-spoke-info deploy-root-app delete-root-app dev-guide infra-guide test


# ============================================================
# help (기본)
# ============================================================
help:
	@echo "=================================================="
	@echo " Management HUB Cluster — Makefile 명령 목록"
	@echo "=================================================="
	@echo ""
	@echo "📖 가이드"
	@echo "  make install-guide                                ArgoCD 최초 설치 가이드 출력"
	@echo "  make dev-guide                                    개발자 가이드 출력"
	@echo "  make infra-guide                                  인프라 관리자 가이드 출력"
	@echo ""
	@echo "🔌 클러스터 연결"
	@echo "  make connect      ENV=<env> CLUSTER=<cluster>    EKS 클러스터 연결 (kubeconfig 등록)"
	@echo "  make use-cluster  ENV=<env> CLUSTER=<cluster>    등록된 컨텍스트로 전환"
	@echo ""
	@echo "🚀 초기 배포"
	@echo "  make bootstrap                                    ArgoCD 부트스트랩 (최초 1회)"
	@echo "  make deploy-root-app ENV=<env> CLUSTER=<cluster> 루트 앱 배포"
	@echo "  make delete-root-app ENV=<env> CLUSTER=<cluster> 루트 앱 삭제 (Non-Cascading)"
	@echo ""
	@echo "🔧 운영"
	@echo "  make sync-auth                                    ArgoCD 인증 서버 재시작"
	@echo "  make describe-app                                 ArgoCD 앱 상세 조회"
	@echo ""
	@echo "🖧  스포크 클러스터"
	@echo "  make setup-spoke                                  스포크 헬름 배포 + 연결 정보 출력"
	@echo "  make get-spoke-info                               스포크 연결 정보 조회"
	@echo ""
	@echo "  ENV     : dev | prod | local"
	@echo "  CLUSTER : mgmt-hub | aiagent | cms | elasticsearch-cluster"
	@echo "=================================================="


# ============================================================
# dev-guide - 개발자 가이드
# ============================================================
dev-guide:
	@echo "📄 [dev-guide] md/DEVELOPER_GUIDE.md"
	@echo ""
	@cat md/DEVELOPER_GUIDE.md


# ============================================================
# infra-guide - 인프라 관리자 가이드
# ============================================================
infra-guide:
	@echo "📄 [infra-guide] md/INFRA_ADMIN_GUIDE.md"
	@echo ""
	@cat md/INFRA_ADMIN_GUIDE.md


# ============================================================
# install-guide - ArgoCD 최초 설치 가이드 (관리자 전용, 1회)
# ============================================================
install-guide:
	@echo "=================================================="
	@echo "⚠️  ArgoCD 최초 설치 가이드 (관리자 전용, 1회)"
	@echo "=================================================="
	@echo ""
	@echo "📦 [사전 준비] 로컬 패키지 설치 (각자 설치):"
	@echo "   brew install kubectl"
	@echo "   brew install awscli"
	@echo "   brew install argocd"
	@echo ""
	@echo "▶ [1/3] argocd 네임스페이스 생성:"
	@echo "   kubectl create namespace argocd"
	@echo ""
	@echo "▶ [2/3] ArgoCD 설치:"
	@echo "  ㅁ kubectl sdasdasdas apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
	@echo ""
	@echo "▶ [3/3] 설치 확인:"
	@echo "   kubectl get all -n argocd"
	@echo ""
	@echo "=================================================="
	@echo "🔑 초기 어드민 비밀번호 확인:"
	@echo "   kubectl -n argocd get secret argocd-initial-admin-secret \\"
	@echo "     -o jsonpath='{.data.password}' | base64 -d"
	@echo ""
	@echo "🌐 UI 접속 (포트포워딩):"
	@echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
	@echo "   → https://localhost:8080"
	@echo ""
	@echo "⚠️  접속 후 반드시 어드민 비밀번호를 변경하세요!"
	@echo "=================================================="

# ============================================================
#  유효성 검사
# ============================================================
validate:
	@if [ -z "$(filter $(CLUSTER),$(ALLOWED_CLUSTER))" ]; then \
		echo "❌ [Error] 유효하지 않은 클러스터입니다: '$(CLUSTER)'"; \
		echo "   👉 허용된 목록: $(ALLOWED_CLUSTER)"; \
		exit 1; \
	fi
	@if [ -z "$(filter $(ENV),$(ALLOWED_ENVS))" ]; then \
		echo "❌ [Error] 유효하지 않은 환경: '$(ENV)'"; \
		echo "   👉 허용된 목록: $(ALLOWED_ENVS)"; \
		exit 1; \
	fi
	@echo "✅ [Validate] 검증 통과: $(ENV)-$(CLUSTER)"


# ============================================================
# connect - EKS 클러스터에 kubeconfig 연결
# ============================================================
connect: validate
	@echo "🔍 [connect] AWS EKS 클러스터 목록 조회 중..."
	@MATCHED=$$(aws eks list-clusters --region $(AWS_REGION) --query 'clusters[]' --output text | tr '\t' '\n' | grep "$(ENV)-$(CLUSTER)"); \
	COUNT=$$(echo "$$MATCHED" | grep -c . 2>/dev/null || echo 0); \
	if [ -z "$$MATCHED" ]; then \
		echo "❌ [connect] 매칭되는 클러스터가 없습니다: '$(ENV)-$(CLUSTER)'"; \
		echo "   👉 현재 존재하는 클러스터 목록:"; \
		aws eks list-clusters --region $(AWS_REGION) --query 'clusters[]' --output text | tr '\t' '\n' | sed 's/^/      - /'; \
		exit 1; \
	fi; \
	if [ "$$COUNT" -gt 1 ]; then \
		echo "❌ [connect] 매칭되는 클러스터가 여러 개입니다:"; \
		echo "$$MATCHED" | sed 's/^/      - /'; \
		echo "   👉 더 구체적인 CLUSTER 값을 입력해주세요."; \
		exit 1; \
	fi; \
	echo "✅ [connect] 클러스터 발견: $$MATCHED"; \
	echo "🔗 [connect] kubeconfig 업데이트 중..."; \
	aws eks update-kubeconfig --region $(AWS_REGION) --name $$MATCHED; \
	echo "✅ [connect] 완료 — 현재 context: $$MATCHED"


# ============================================================
# use-cluster - kubeconfig 에 등록된 컨텍스트로 전환
# ============================================================
use-cluster: validate
	@echo "🔍 [use-cluster] kubeconfig 컨텍스트 목록 조회 중..."
	@MATCHED=$$(kubectl config get-contexts --no-headers -o name | grep "$(ENV)-$(CLUSTER)"); \
	COUNT=$$(echo "$$MATCHED" | grep -c . 2>/dev/null || echo 0); \
	if [ -z "$$MATCHED" ]; then \
		echo "❌ [use-cluster] 매칭되는 컨텍스트가 없습니다: '$(ENV)-$(CLUSTER)'"; \
		echo "   👉 현재 등록된 컨텍스트 목록:"; \
		kubectl config get-contexts --no-headers -o name | sed 's/^/      - /'; \
		exit 1; \
	fi; \
	if [ "$$COUNT" -gt 1 ]; then \
		echo "❌ [use-cluster] 매칭되는 컨텍스트가 여러 개입니다:"; \
		echo "$$MATCHED" | sed 's/^/      - /'; \
		echo "   👉 더 구체적인 CLUSTER 값을 입력해주세요."; \
		exit 1; \
	fi; \
	echo "✅ [use-cluster] 컨텍스트 발견: $$MATCHED"; \
	kubectl config use-context $$MATCHED; \
	echo "✅ [use-cluster] 완료 — 현재 context: $$MATCHED"

# ============================================================
# !!부트스트랩!! 초기 딱 1번만	!!경고!!
# ============================================================
bootstrap:
	@echo "⚠️  [bootstrap] Management HUB 전체 부트스트랩을 실행합니다."
	@echo "   - argocd/bootstrap/init-hub-repo-secret.yaml"
	@echo "   - argocd/bootstrap/root-hub-setup.yaml"
	@echo ""
	@read -p "계속하려면 'y' 를 입력하세요: " CONFIRM; \
	if [ "$$CONFIRM" != "y" ]; then \
		echo "❌ [bootstrap] 취소되었습니다."; \
		exit 1; \
	fi
	read -p "정말로 실행하시겠습니까? 다시 한번 'y' 를 입력하세요: " CONFIRM2; \
	if [ "$$CONFIRM2" != "y" ]; then \
		echo "❌ [TEST] 취소되었습니다."; \
		exit 1; \
	fi
	@echo "🚀 [bootstrap] 시작..."
	@kubectl apply -f argocd/bootstrap/init-hub-repo-secret.yaml
	@kubectl apply -f argocd/bootstrap/root-hub-setup.yaml
	@echo "✅ [bootstrap] 완료"

# ============================================================
# 부트스트랩 이후 또는 oauth 변경 하고나서 oauth 서버 재시작
# ============================================================
sync-auth:
	@echo "🚀 [sync-auth] 서버 재시작..."
	@kubectl rollout restart deployment argocd-server -n argocd
	@kubectl rollout restart deployment argocd-dex-server -n argocd
	@echo "⏳ [sync-auth] rollout 완료 대기 중..."
	@kubectl rollout status deployment argocd-server -n argocd
	@kubectl rollout status deployment argocd-dex-server -n argocd
	@echo "✅ [sync-auth] 완료"

# ============================================================
# 쿠버네티스 application 조회
# ============================================================
describe-app:
	@echo "ℹ️  [describe-app] 앱 이름 규칙: {환경}-{클러스터}-{앱이름} (예: dev-clusterA-testapp)"
	@echo "📋 [describe-app] 등록된 애플리케이션 목록:"
	@kubectl get application -n argocd
	@echo ""
	@read -p "조회할 애플리케이션 풀네임을 입력하세요: " APP; \
	if kubectl get application $$APP -n argocd > /dev/null 2>&1; then \
		kubectl describe application $$APP -n argocd; \
	else \
		echo "❌ [describe-app] '$$APP' 을 찾을 수 없습니다."; \
		exit 1; \
	fi
	
# ============================================================
# setup-spoke - 스포크 클러스터 헬름 배포 + 연결 정보 출력
# ============================================================
setup-spoke:
	@echo "⚠️  [setup-spoke] 스포크(타겟) 클러스터가 맞나요?"
	@echo ""
	@read -p "맞다면 'y' 를 입력하세요: " CONFIRM; \
	if [ "$$CONFIRM" != "y" ]; then \
		echo "❌ [setup-spoke] 취소되었습니다."; \
		exit 1; \
	fi
	@echo "🚀 [setup-spoke] target-cluster-setup 헬름 배포 중..."
	@helm upgrade --install target-cluster-setup helm-charts/argocd-manager/target-cluster-setup/ \
		-n argocd-manager \
		--create-namespace \
		-f helm-charts/argocd-manager/target-cluster-setup/values.yaml
	@echo "✅ [setup-spoke] 헬름 배포 완료"
	@echo ""
	@$(MAKE) get-spoke-info


# ============================================================
# get-spoke-info - 스포크 클러스터 연결 정보 조회
# ============================================================
get-spoke-info:
	@echo "=========================================="
	@echo "🔑 Bearer Token (디코딩):"
	@echo "=========================================="
	@kubectl get secret argocd-manager-token \
		-n argocd-manager \
		-o jsonpath='{.data.token}' | base64 --decode
	@echo ""
	@echo ""
	@echo "=========================================="
	@echo "📜 CA Certificate (base64 인코딩):"
	@echo "=========================================="
	@kubectl -n argocd-manager get secret argocd-manager-token \
		-o jsonpath='{.data.ca\.crt}'
	@echo ""
	@echo ""
	@echo "=========================================="
	@echo "🌐 k8s API Endpoint:"
	@echo "=========================================="
	@kubectl config view --minify --output jsonpath='{.clusters[0].cluster.server}'
	@echo ""
	@echo "=========================================="


# ============================================================
# deploy-root-app - 루트 앱 배포
# ============================================================
deploy-root-app: validate
	@echo "🚀 [deploy-root-app] 배포 대상: argocd/clusters/$(CLUSTER)/root-app-$(ENV).yaml"
	@read -p "계속하려면 'y' 를 입력하세요: " CONFIRM; \
	if [ "$$CONFIRM" != "y" ]; then \
		echo "❌ [deploy-root-app] 취소되었습니다."; \
		exit 1; \
	fi
	@kubectl apply -f argocd/clusters/$(CLUSTER)/root-app-$(ENV).yaml
	@echo "✅ [deploy-root-app] 완료"


# ============================================================
# delete-root-app - 루트 앱 Non-Cascading 삭제
# ============================================================
delete-root-app: validate
	@echo "⚠️  [delete-root-app] 삭제 대상: $(ENV)-$(CLUSTER) (Non-Cascading)"
	@echo "   ℹ️  하위 리소스는 삭제되지 않습니다."
	@read -p "계속하려면 'y' 를 입력하세요: " CONFIRM; \
	if [ "$$CONFIRM" != "y" ]; then \
		echo "❌ [delete-root-app] 취소되었습니다."; \
		exit 1; \
	fi
	@argocd app delete $(ENV)-$(CLUSTER) --cascade=false
	@echo "✅ [delete-root-app] 완료"



kubectl port-forward svc/argocd-server -n argocd 8080:443
아후 로컬호스트 로 접속

베포
카드에 synced 가 최신반영.
카드에 status가 outofsync 일때 수동 베포 가능
app 카드에 sync 클릭. -> 왼쪽상단에 SYNCHRONIZE 클릭
health 상태가 progresssing 이면 베포중. 헬시로 되면 베포완


개발은 자동베포.
운영은 수동베포

github,bitbucket 에서 pipe,action 으로 ci 및 이미지 등록 및 변경사항 버전 푸쉬
argo 에서 적용


카드클릭 맨오른쪽 클릭 logs,evnets 확인가능. 맨왼쪽에서 diff 다른거확인가능

UI 삭제 시 선택 옵션
Delete 버튼 누르면 팝업에서 선택 가능:

Foreground - 리소스 다 지우고 앱 삭제
Background - 앱 먼저 삭제 후 리소스 정리
Non-cascading - 앱만 삭제, 리소스 유지 (finalizer 무시)



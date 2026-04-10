{{/*
Expand the name of the chart.
helm install 로 만드세요!
*/}}
{{- define "helm install 로 만드세요!" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- define "apps.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

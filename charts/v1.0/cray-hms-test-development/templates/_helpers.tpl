{{/*
Helper function to get the proper image tag
*/}}
{{- define "cray-hms-test-development.imageTag" -}}
{{- default "latest" .Values.global.appVersion -}}
{{- end -}}

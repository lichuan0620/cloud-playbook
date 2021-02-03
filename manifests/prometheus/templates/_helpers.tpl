{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "common.names.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.names.fullname" -}}
{{- if contains .Chart.Name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "common.names.serviceAccountName" -}}
{{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- end -}}
{{/*
Create the name of the service account to use
*/}}
{{- define "common.names.prometheusRule" -}}
{{- printf "%s-default-recording-rules" .Release.Name }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "common.labels.standard" -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
    {{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
    {{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
    {{- if .Values.labels }}
{{toYaml .Values.labels}}
    {{- end }}
{{- end -}}

{{/*
matchLabels
*/}}
{{- define "common.labels.matchLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "prometheus.image" -}}
{{- $tag := (default .Chart.AppVersion .Values.image.tag) | toString -}}
{{- printf "%s:%s" .Values.image.name $tag -}}
{{- end -}}
{{- define "thanos.image" -}}
{{- $tag := (default .Chart.AppVersion .Values.thanos.image.tag) | toString -}}
{{- printf "%s:%s" .Values.thanos.image.name $tag -}}
{{- end -}}

{{- define "prometheus.additionalConfig.defaultSecretName" }}
{{- .Release.Name }}-additional-configs
{{- end }}

{{- define "prometheus.externalURL" }}
{{- $protocol := "http" -}}
{{ if .Values.ingress.tlsSecretName }}
  {{- $protocol = "https" -}}
{{ end }}
{{- printf "%s://%s%s" $protocol .Values.ingress.host .Values.ingress.prefix -}}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "tty-bridge.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "tty-bridge.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tty-bridge.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "tty-bridge.labels" -}}
helm.sh/chart: {{ include "tty-bridge.chart" . }}
{{ include "tty-bridge.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "tty-bridge.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tty-bridge.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ConfigMap name.
*/}}
{{- define "tty-bridge.configMapName" -}}
{{- default (printf "%s-config" (include "tty-bridge.fullname" .)) .Values.configMap.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Ingress name.
*/}}
{{- define "tty-bridge.ingressName" -}}
{{- default (include "tty-bridge.fullname" .) .Values.ingress.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Primary ingress host.
*/}}
{{- define "tty-bridge.ingressHost" -}}
{{- printf "%s.%s" .Values.ingress.hostPrefix .Values.cloudDomain -}}
{{- end }}

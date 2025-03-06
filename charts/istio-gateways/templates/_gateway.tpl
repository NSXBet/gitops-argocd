{{- define "istio-gateways.gateway" }}
{{- if .Gateway.enabled }}
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: {{ printf "%s-gateway" .Gateway.name }}
  namespace: {{ .Gateway.namespace | default .General.namespace }}
spec:
  selector:
    {{- if .Gateway.selector }}
    {{- toYaml .Gateway.selector | nindent 4 }}
    {{- else }}
    app: {{ printf "istio-%s-ingressgateway" .Gateway.ingressName }}
    istio: {{ printf "istio-%s-ingressgateway" .Gateway.ingressName }}
    {{- end }}
  servers:
{{- range .Gateway.domains }}
  {{- $portName := .fqdn | kebabcase }}
  {{- /* Create a port for the given protocol and port */}}
  {{- if .port }}
  - hosts:
    - {{ .fqdn | quote }}
    port:
      name: {{ printf "%s-%s-%s" .protocol  $.Gateway.name $portName | lower | quote }}
      number: {{ .port }}
      protocol: {{ .protocol | upper }}
    {{- if .httpsRedirect }}
    tls:
      httpsRedirect: {{ .httpsRedirect }}
    {{- end }}
  {{- else }}
  {{- /* Create a port for HTTP and HTTPS */}}
  - hosts:
    - {{ .fqdn | quote }}
    port:
      name: {{ printf "http-%s-%s" $.Gateway.name $portName | lower | quote }}
      number: 80
      protocol: HTTP
    tls:
      httpsRedirect: {{ .httpsRedirect | default true }}
  - hosts:
    - {{ .fqdn | quote }}
    port:
      name: {{ printf "https-%s-%s" $.Gateway.name $portName | lower | quote }}
      number: 443
    {{- if not .tls }}
      protocol: HTTP
    {{- end }}
    {{- if .tls }}
      protocol: HTTPS
    tls:
      mode: {{ .tls.mode | upper }}
      {{- if .tls.certSecret }}
      credentialName: {{ .tls.certSecret }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- else }}
# Gateway "{{ .Gateway.name }}" is disabled
{{- end }}
{{- end }}

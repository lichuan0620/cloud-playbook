{{- define "prometheus.additionalConfig.scrapeConfig" -}}
- job_name: {{ .Release.Name }}
  static_configs:
  - targets: ['localhost:9090']

- job_name: cadvisor
  kubernetes_sd_configs:
  - role: node
  tls_config:
    insecure_skip_verify: true
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  metrics_path: /metrics/cadvisor
  scheme: https

- job_name: kubelet
  kubernetes_sd_configs:
  - role: node
  tls_config:
    insecure_skip_verify: true
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  scheme: https
  relabel_configs:
  - source_labels: [__meta_kubernetes_node_name]
    target_label: node
  - source_labels: [__meta_kubernetes_node_address_internalIP]
    target_label: host_ip

- job_name: node-exporter
  kubernetes_sd_configs:
  - role: endpoints
    namespaces:
      names:
      - {{ .Release.Namespace }}
  relabel_configs:
  - source_labels: [__meta_kubernetes_service_name]
    regex: node-exporter
    action: keep
  - source_labels: [__meta_kubernetes_pod_node_name]
    target_label: node
  - source_labels: [__meta_kubernetes_pod_host_ip]
    target_label: host_ip

- job_name: kube-state-metrics
  kubernetes_sd_configs:
  - role: endpoints
    namespaces:
      names:
      - {{ .Release.Namespace }}
  relabel_configs:
  - source_labels: [__meta_kubernetes_service_name]
    regex: kube-state-metrics
    action: keep
  - source_labels: [__meta_kubernetes_endpoint_port_name]
    regex: http
    action: keep

- job_name: kube-apiserver
  kubernetes_sd_configs:
  - role: node
  scheme: https
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    insecure_skip_verify: true
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  relabel_configs:
  - source_labels: [__meta_kubernetes_node_label_kubernetes_io_role]
    regex: master
    action: keep
  - source_labels: [__address__]
    regex: ([^:]+)(?::\d+)?
    replacement: $1:443
    target_label: __address__
  - source_labels: [__meta_kubernetes_node_name]
    target_label: node
  - source_labels: [__meta_kubernetes_node_address_internalIP]
    target_label: host_ip

- job_name: kube-scheduler
  kubernetes_sd_configs:
  - role: node
  relabel_configs:
  - source_labels: [__meta_kubernetes_node_label_kubernetes_io_role]
    regex: master
    action: keep
  - source_labels: [__address__]
    regex: ([^:]+)(?::\d+)?
    replacement: $1:10251
    target_label: __address__
  - source_labels: [__meta_kubernetes_node_name]
    target_label: node
  - source_labels: [__meta_kubernetes_node_address_internalIP]
    target_label: host_ip

- job_name: kube-controller-manager
  kubernetes_sd_configs:
  - role: node
  relabel_configs:
  - source_labels: [__meta_kubernetes_node_label_kubernetes_io_role]
    regex: master
    action: keep
  - source_labels: [__address__]
    regex: ([^:]+)(?::\d+)?
    replacement: $1:10252
    target_label: __address__
  - source_labels: [__meta_kubernetes_node_name]
    target_label: node
  - source_labels: [__meta_kubernetes_node_address_internalIP]
    target_label: host_ip

- job_name: 'etcd-main'
  scheme: https
  tls_config:
    insecure_skip_verify: true
    ca_file: /etc/prometheus/secrets/etcd-tls-secret/etcd-ca.crt
    key_file: /etc/prometheus/secrets/etcd-tls-secret/etcd-client.key
    cert_file: /etc/prometheus/secrets/etcd-tls-secret/etcd-client.crt
  kubernetes_sd_configs:
  - role: node
  relabel_configs:
  - source_labels: [__meta_kubernetes_node_label_kubernetes_io_role]
    regex: master
    action: keep
  - source_labels: [__address__]
    regex: ([^:]+)(?::\d+)?
    replacement: $1:4001
    target_label: __address__
  - source_labels: [__meta_kubernetes_node_name]
    target_label: node
  - source_labels: [__meta_kubernetes_node_address_internalIP]
    target_label: host_ip

- job_name: 'etcd-events'
  scheme: https
  tls_config:
    insecure_skip_verify: true
    ca_file: /etc/prometheus/secrets/etcd-tls-secret/etcd-ca.crt
    key_file: /etc/prometheus/secrets/etcd-tls-secret/etcd-client.key
    cert_file: /etc/prometheus/secrets/etcd-tls-secret/etcd-client.crt
  kubernetes_sd_configs:
  - role: node
  relabel_configs:
  - source_labels: [__meta_kubernetes_node_label_kubernetes_io_role]
    regex: master
    action: keep
  - source_labels: [__address__]
    regex: ([^:]+)(?::\d+)?
    replacement: $1:4002
    target_label: __address__
  - source_labels: [__meta_kubernetes_node_name]
    target_label: node
  - source_labels: [__meta_kubernetes_node_address_internalIP]
    target_label: host_ip
{{- end -}}

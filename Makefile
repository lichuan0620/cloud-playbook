NODE_COUNT ?= 1
NODE_SIZE ?= m5.large
NODE_VOLUME_SIZE ?= 30

MASTER_COUNT ?= 3
MASTER_SIZE ?= c5.large
MASTER_VOLUME_SIZE ?= 20

ZONES ?= us-west-2a
HA_ZONES ?= us-west-2a,us-west-2b,us-west-2c

.PHONY: cluster cluster-single cluster-ha

cluster: cluster-single

cluster-single:
	@echo ">> creating cluster $(KOPS_CLUSTER_NAME)"
	@kops create cluster												\
	  --node-count $(NODE_COUNT)										\
	  --node-size $(NODE_SIZE)											\
	  --node-volume-size $(NODE_VOLUME_SIZE)							\
	  --master-size $(MASTER_SIZE)										\
	  --master-volume-size $(MASTER_VOLUME_SIZE)						\
	  --zones $(ZONES) --cloud aws										\
	  --cloud-labels "kubernetes.io/cluster/$(KOPS_CLUSTER_NAME)=owned"
	@echo ">> applying additional cluster configuration"
	@kops replace -f kops/single-master-cluster.yaml
	@echo ">> building cluster"
	@kops update cluster --yes

cluster-ha:
	@echo ">> creating cluster $(KOPS_CLUSTER_NAME)"
	@kops create cluster --cloud aws									\
      --node-count $(NODE_COUNT)										\
      --node-size $(NODE_SIZE)											\
      --node-volume-size $(NODE_VOLUME_SIZE)							\
      --master-count $(MASTER_COUNT)									\
      --master-size $(MASTER_SIZE)										\
      --master-volume-size $(MASTER_VOLUME_SIZE)						\
      --zones $(HA_ZONES)												\
      --cloud-labels "kubernetes.io/cluster/$(KOPS_CLUSTER_NAME)=owned"
	@echo ">> applying additional cluster configuration"
	@kops replace -f kops/ha-cluster.yaml
	@echo ">> building cluster"
	@kops update cluster --yes

.PHONY: validate apply-deploy system-components

validate:
	@echo ">> validating the cluster"
	@kops validate cluster
	@kubectl get nodes --show-labels

apply-deploy:
	@echo ">> applying basic resources"
	@kubectl apply -f deploy
	@echo ">> creating ETCD secrets"
	@ssh-keygen -R api.k8s.lichuan.guru
	@ssh admin@api.k8s.lichuan.guru	-y '								\
	  sudo kubectl create -n system secret generic etcd-tls-secret		\
        --from-file=/etc/kubernetes/pki/kube-apiserver/etcd-ca.crt		\
        --from-file=/etc/kubernetes/pki/kube-apiserver/etcd-client.crt	\
        --from-file=/etc/kubernetes/pki/kube-apiserver/etcd-client.key'
	@kubectl create secret -n system generic							\
	  prometheus-operator-prometheus-scrape-config						\
	  --from-file=extra/additional-scrape-configs.yaml

system-components:
	@echo ">> adding helm repo bitnami"
	@helm repo add bitnami https://charts.bitnami.com/bitnami
	@echo ">> installing metrics-server"
	@helm install metrics-server bitnami/metrics-server -n kube-system 		\
	  -f helm/bitnami-metrics-server.yaml --atomic --timeout 1m
	@echo ">> installing prometheus-operator"
	@kubectl create secret -n system generic prometheus-operator-prometheus-scrape-config	\
	  --from-file=extra/additional-scrape-configs.yaml
	@helm install prometheus-operator bitnami/prometheus-operator -n system \
	  -f helm/bitnami-prometheus-operator.yaml --atomic --timeout 1m
	@echo ">> installing node-exporter"
	@helm install node-exporter bitnami/node-exporter -n system \
	  -f helm/bitnami-node-exporter.yaml --atomic --timeout 1m
	@echo ">> installing kube-statie-metrics"
	@helm install kube-state-metrics bitnami/kube-state-metrics -n system \
	  -f helm/bitnami-kube-state-metrics.yaml --atomic --timeout 1m
	@echo ">> installing grafana"
	@helm install grafana bitnami/grafana -n system \
	  -f helm/bitnami-grafana.yaml --atomic --timeout 1m


.PHONY: clean

clean:
	@echo ">> cleaning up"
	@kops delete cluster --yes
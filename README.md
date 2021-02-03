# Note for Self: Building a Basic K8s Cluster

`kops` is an excellent option for installing on AWS. The following note outlines the most important steps to build a basic DNS-based cluster with `kops`.

Follow the [original guide](https://kops.sigs.k8s.io/getting_started/aws/) to make sure the prerequisites are met, **especially the part with IMA**.

Do some basic config (note that some of these ENV are used automatically by kops):

```
export KUBECONFIG=~/.kube/config
export KOPS_CLUSTER_NAME=k8s.lichuan.guru
export KOPS_STATE_STORE=s3://kube-lichuan-guru-state-store
```

Run `ssh-keygen` if the `~/.ssh/id_rsa` file is missing.

If you want to use custom security group and VPC, you might want to create them now.

```
export VPC_ID ?= vpc-05a60f2ce4fc6e8ad
export NETWORK_CIDR = 172.19.0.0/16
```

## Building the Cluster

### Setup

Single master

```
kops create cluster                                                 \
  --node-count 2 --node-size t3.large --node-volume-size 20         \
  --master-size t3.large --master-volume-size 20                    \
  --zones ap-northeast-1a --cloud aws --vpc $(VPC_ID)               \
  --cloud-labels "kubernetes.io/cluster/k8s.lichuan.guru=owned"
```

HA (3 masters)

```
WIP
```

### Optional Manual Setups

Afterwards, a few things need to be edited manually:

Cluster related, run `kops edit cluster`

 * To allow service account token to communicate with kubelet, add:
   ```
   spec:
     kubelet:
       anonymousAuth: false
       authorizationMode: Webhook
       authenticationTokenWebhook: true
   ```
 * To use containerd instead of Docker for CRI, add:
   ```
   spec:
     containerRuntime: containerd
   ```
   
Node related, run `kops edit ig --name=k8s.lichuan.guru nodes` and `kops edit ig --name=k8s.lichuan.guru master-us-west-2a`

 * To specify custom security group, add:
   ```
   spec:
     securityGroupOverride: sg-0d3b4041701f62479
   ```

To use a private topology, a non-default [networking model](https://kops.sigs.k8s.io/networking/) must be used.

### Building

If you did not use custom security group:

```
kops update cluster --yes
```

If you used custom security group:

```
kops update cluster --yes \
  --lifecycle-overrides SecurityGroup=ExistsAndWarnIfChanges,SecurityGroupRule=ExistsAndWarnIfChanges
```

 * validate cluster: `kops validate cluster`
 * list nodes: `kubectl get nodes --show-labels`
 * ssh to the master: `ssh -i ~/.ssh/id_rsa admin@api.k8s.lichuan.guru`
 * the admin user is specific to Debian. If not using Debian please use the appropriate user based on your OS.
 * read about installing addons at: https://github.com/kubernetes/kops/blob/master/docs/operations/addons.md.
 
In case you accessed the cluster before the DNS configuration is fully updated, you might want to flush the DNS cache before you try again.

## Setup the Cluster

Most of the addons below are installed via Helm. Add the repo first:

```
helm repo add   ingress-nginx   https://kubernetes.github.io/ingress-nginx
helm repo add   bitnami         https://charts.bitnami.com/bitnami
```

### Monitoring - Control Plane

__Namesapce__

```
kubectl create ns monitoring
```

__metrics-server__

```
helm install -n kube-system -f helm-values/metrics-server.yaml \
  metrics-server bitnami/metrics-server --atomic --timeout 1m
```

__prometheus-operator__

```
helm install -n monitoring \
  prometheus-operator manifests/prometheus-operator --atomic --timeout 1m
```

### Network - LB and Ingress

__Namespace__

```
kubectl create ns network
```

__ingress-nginx__

```
export LB_NODE=kube-node-1
kubectl label node ${LB_NODE} lichuan.guru/role=loadbalancer
helm install -n network -f helm-values/ingress-nginx.yaml \
  ingress-nginx ingress-nginx/ingress-nginx --atomic --timeout 1m
```

__cert-manager__

```
helm install -n network -f helm-values/cert-manager.yaml \
  cert-manager jetstack/cert-manager --atomic --timeout 1m
kubectl create -f deploy/letsencrypt-cert-manager-cluster-issuer.yaml
```

### Monitoring - Engine

__kube-state-metrics__

```
helm install -n monitoring -f helm-values/kube-state-metrics \
  kube-state-metrics bitnami/kube-state-metrics --atomic --timeout 1m
```

__node-exporter__

```
helm install -n monitoring -f helm-values/node-exporter \
  node-exporter bitnami/node-exporter --atomic --timeout 1m
```

__ETCD Secret__

```
ssh ubuntu@api.k8s.lichuan.guru	'								                        \
  sudo cp /etc/kubernetes/pki/kube-apiserver/etcd-ca.crt /tmp/etcd-ca.crt &&            \
  sudo cp /etc/kubernetes/pki/kube-apiserver/etcd-client.crt /tmp/etcd-client.crt &&    \
  sudo cp /etc/kubernetes/pki/kube-apiserver/etcd-client.key /tmp/etcd-client.key &&    \
  sudo chown ubuntu:ubuntu /tmp/etcd-ca.crt &&                                          \
  sudo chown ubuntu:ubuntu /tmp/etcd-client.crt &&                                      \
  sudo chown ubuntu:ubuntu /tmp/etcd-client.key &&                                      \
  kubectl create -n monitoring secret generic etcd-tls-secret		                    \
    --from-file=/tmp/etcd-ca.crt		                                                \
    --from-file=/tmp/etcd-client.crt	                                                \
    --from-file=/tmp/etcd-client.key &&                                                 \
  rm /tmp/etcd-ca.crt /tmp/etcd-client.crt /tmp/etcd-client.key'
```

__Prometheus__

```
helm install -n monitoring \
  system-prometheus manifests/prometheus --atomic --timeout 1m
```

__Grafana__

Before you proceed, define Grafana admin username and password in
`private/grafana-admin-user` and `private/grafana-admin-password`.

```
kubectl create -n monitoring secret generic grafana-admin-auth  \
  --from-file=private/grafana-admin-user                        \
  --from-file=private/grafana-admin-password
helm repo add grafana https://grafana.github.io/helm-charts
helm install -n monitoring -f helm-values/grafana.yaml \
  grafana grafana/grafana --atomic --timeout 1m
```

Add the dashboards:

| Dashboard             | Link                                         |
| :---                  | :---                                         |
| Node Overview         | https://grafana.com/grafana/dashboards/13824 |
| Node Analysis         | WIP                                          |
| Container Overview    | WIP                                          |
| Container Analysis    | WIP                                          |
| Kubernetes Overview   | WIP                                          |
| Ingress Nginx         | WIP                                          |

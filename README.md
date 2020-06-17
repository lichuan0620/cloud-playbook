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

## Building the Cluster

### Setup

Single master

```
kops create cluster                                                 \
  --node-count 2 --node-size t3.medium --node-volume-size 30        \
  --master-size t3.medium --master-volume-size 20                   \
  --zones ap-northeast-1a --cloud aws                               \
  --cloud-labels "kubernetes.io/cluster/k8s.lichuan.guru=owned"

kops replace -f kops/single-master-cluster.yaml
```

HA (3 masters)

```
kops create cluster --cloud aws                                     \
  --node-count 2 --node-size t3.medium --node-volume-size 30        \
  --master-count 3 --master-size t3.medium --master-volume-size 20  \
  --zones ap-northeast-1a,ap-northeast-1c,ap-northeast-1d           \
  --cloud-labels "kubernetes.io/cluster/k8s.lichuan.guru=owned"

kops replace -f kops/ha-cluster.yaml
```

 * list clusters with: `kops get cluster`
 * edit this cluster with: `kops edit cluster k8s.lichuan.guru`
 * edit your node instance group: `kops edit ig --name=k8s.lichuan.guru nodes`
 * edit your master instance group: `kops edit ig --name=k8s.lichuan.guru master-ap-northeast-1a`

Additional configuration must be done via `kops edit cluster` or `kops replace -f kops/single-master-cluster.yaml`. 

To allow service account token to communicate with kubelet, edit the cluster and add:

```
kubelet:
    anonymousAuth: false
    authorizationMode: Webhook
    authenticationTokenWebhook: true
```

To use a private topology, a non-default [networking model](https://kops.sigs.k8s.io/networking/) must be used.

### Building

```
$ kops update cluster --yes
```

 * validate cluster: `kops validate cluster`
 * list nodes: `kubectl get nodes --show-labels`
 * ssh to the master: `ssh -i ~/.ssh/id_rsa admin@api.k8s.lichuan.guru`
 * the admin user is specific to Debian. If not using Debian please use the appropriate user based on your OS.
 * read about installing addons at: https://github.com/kubernetes/kops/blob/master/docs/operations/addons.md.
 
In case you accessed the cluster before the DNS configuration is fully updated, you might want to flush the DNS cache before you try again.

## Setup the Cluster

### Create Useful Secrets

__ETCD Client__

```
# from one of the master nodes
sudo kubectl create -n devops secret generic etcd-tls-secret \
  --from-file=/etc/kubernetes/pki/kube-apiserver/etcd-ca.crt      \
  --from-file=/etc/kubernetes/pki/kube-apiserver/etcd-client.crt  \
  --from-file=/etc/kubernetes/pki/kube-apiserver/etcd-client.key
```

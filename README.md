# Cloud Playbook: Note on Building a Basic K8s Cluster

`kops` is an excellent option for installing on AWS. The following note outlines the most important steps to build a basic cluster with `kops` in gossip mode.

Follow the [original guide](https://kops.sigs.k8s.io/getting_started/aws/) to make sure the prerequisites are met.

## Building the Cluster

### Setup

```
$ kops create cluster --node-count 2 --node-size t3.medium --master-size t3.medium --zones ap-northeast-1a --cloud aws`
```

 * list clusters with: `kops get cluster`
 * edit this cluster with: `kops edit cluster lichuan.guru.k8s.local`
 * edit your node instance group: `kops edit ig --name=lichuan.guru.k8s.local nodes`
 * edit your master instance group: `kops edit ig --name=lichuan.guru.k8s.local master-ap-northeast-1a`

### Building

```
$ kops update cluster --name ${KOPS_CLUSTER_NAME} --yes
```

 * validate cluster: `kops validate cluster`
 * list nodes: `kubectl get nodes --show-labels`
 * ssh to the master: `ssh -i ~/.ssh/id_rsa admin@api.lichuan.guru.k8s.local`
 * the admin user is specific to Debian. If not using Debian please use the appropriate user based on your OS.
 * read about installing addons at: https://github.com/kubernetes/kops/blob/master/docs/operations/addons.md.

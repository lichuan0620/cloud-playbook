NODE_COUNT ?= 1
NODE_SIZE ?= t3.large
NODE_VOLUME_SIZE ?= 32

MASTER_COUNT ?= 3
MASTER_SIZE ?= t3.medium
MASTER_VOLUME_SIZE ?= 32

SSH_ACCESS ?= 18.180.136.55/32

CNI ?= canal
VPC_ID ?= vpc-0816493a03e601027
NETWORK_CIDR = 192.168.0.0/16
MASTER_SECURITY_GROUPS ?= sg-08a724db4f88b5dff
NODE_SECURITY_GROUPS ?= sg-05afffe3ef9893321

ZONES ?= us-west-2a
HA_ZONES ?= us-west-2a,us-west-2b,us-west-2c

.PHONY: cluster cluster-single cluster-ha

cluster: cluster-ha

cluster-single:
	@echo ">> creating cluster $(KOPS_CLUSTER_NAME)"
	@kops create cluster --cloud aws                                      \
      --node-count $(NODE_COUNT)                                        \
      --node-size $(NODE_SIZE)                                          \
      --node-volume-size $(NODE_VOLUME_SIZE)                            \
      --master-size $(MASTER_SIZE)                                      \
      --master-volume-size $(MASTER_VOLUME_SIZE)                        \
      --master-security-groups $(MASTER_SECURITY_GROUPs)                \
      --zones $(ZONES)                                                  \
      --vpc $(VPC_ID)                                                   \
      --network-cidr $(NETWORK_CIDR)                                    \
      --cloud-labels "$(KOPS_CLUSTER_NAME)=owned"

cluster-ha:
	@echo ">> creating cluster $(KOPS_CLUSTER_NAME)"
	@kops create cluster --cloud aws                                      \
      --ssh-access $(SSH_ACCESS)                                        \
      --node-count $(NODE_COUNT)                                        \
      --node-size $(NODE_SIZE)                                          \
      --node-volume-size $(NODE_VOLUME_SIZE)                            \
      --node-security-groups $(NODE_SECURITY_GROUPS)                    \
      --master-count $(MASTER_COUNT)                                    \
      --master-size $(MASTER_SIZE)                                      \
      --master-volume-size $(MASTER_VOLUME_SIZE)                        \
      --master-security-groups $(MASTER_SECURITY_GROUPS)                \
      --networking $(CNI)                                               \
      --zones $(HA_ZONES)                                               \
      --vpc $(VPC_ID)                                                   \
      --network-cidr $(NETWORK_CIDR)                                    \
      --cloud-labels "$(KOPS_CLUSTER_NAME)=owned"

.PHONY: create

build:
	@kops update cluster --yes --admin=87600h

.PHONY: clean

clean:
	@echo ">> cleaning up"
	@kops delete cluster --yes

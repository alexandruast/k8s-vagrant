#!/usr/bin/env bash
set -eEuo pipefail
trap 'RC=$?; echo [error] exit code $RC running $BASH_COMMAND; exit $RC' ERR

SSH_OPTS='-o LogLevel=error -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes'

install_jq() {
  sudo curl -LSs https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq \
  && sudo chmod +x /usr/local/bin/jq
}

install_pip() {
  curl -LSs "https://bootstrap.pypa.io/get-pip.py" | sudo python
}

install_ansible() {
  sudo pip install ansible==2.5.2
}

sudo yum -q -y install python libselinux-python

which pip >/dev/null || install_pip
which ansible >/dev/null || install_ansible
which jq >/dev/null || install_jq

cd /vagrant/

KUBE_MASTER=$1
KUBE_NODES="$(echo $2 | jq -re .[].ip | tr '\n' ',' | sed -e 's/,$/\n/')"

ANSIBLE_TARGET="${KUBE_MASTER},${KUBE_NODES}" \
  ./apl-wrapper.sh ansible/target-kubernetes.yml

cmd="sudo kubeadm init --apiserver-advertise-address=${KUBE_MASTER} --pod-network-cidr=10.244.0.0/16"
echo "running ${cmd}, please wait..."
result=$(${cmd})

node_join_cmd="$(echo "${result}" | grep -e "discovery-token-ca-cert-hash")"

for node in $(echo "${KUBE_NODES}" | tr ',' '\n'); do
  ssh ${SSH_OPTS} ${node} "sudo ${node_join_cmd}"
done

cd ${HOME}

mkdir -p ${HOME}/.kube
sudo cp -i /etc/kubernetes/admin.conf ${HOME}/.kube/config
sudo chown "$(id -u)":"$(id -g)" ${HOME}/.kube/config

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

curl -SsL https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-linux-amd64.tar.gz | tar zxv \
  && sudo mv ./linux-amd64/helm /usr/local/bin \
  && sudo chown root:root /usr/local/bin/helm \
  && rm -fr ./linux-amd64
 
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
kubectl create clusterrolebinding serviceaccounts-cluster-admin --clusterrole=cluster-admin --group=system:serviceaccounts
 
helm init
helm repo update

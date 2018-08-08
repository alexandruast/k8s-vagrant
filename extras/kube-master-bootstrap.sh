#!/usr/bin/env bash
set -eEuo pipefail
trap 'RC=$?; echo [error] exit code $RC running $BASH_COMMAND; exit $RC' ERR

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


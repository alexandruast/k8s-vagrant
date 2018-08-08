#!/usr/bin/env bash
set -eEuo pipefail
trap 'RC=$?; echo [error] exit code $RC running $BASH_COMMAND; exit $RC' ERR

K8S_MASTERS="$(echo $1 | jq -re .[].ip | tr '\n' ',' | sed -e 's/,$/\n/')"
K8S_NODES="$(echo $2 | jq -re .[].ip | tr '\n' ',' | sed -e 's/,$/\n/')"

SSH_CONTROL_SOCKET="/tmp/ssh-control-socket-$(uuidgen)"
trap 'sudo ssh -S "${SSH_CONTROL_SOCKET}" -O exit vagrant@${!ip_addr_var:-192.0.2.255}' EXIT

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

# Overwrites Origin-Jenkins ssh key pair, created by Ansible in previous steps
overwrite_origin_keypair() {
  cat /home/vagrant/.ssh/id_rsa | sudo tee /home/jenkins/.ssh/id_rsa >/dev/null
  ssh-keygen -y -f "$HOME/.ssh/id_rsa" | sudo tee /home/jenkins/.ssh/id_rsa.pub >/dev/null
}

sudo yum -q -y install python libselinux-python

which pip >/dev/null || install_pip
which ansible >/dev/null || install_ansible
which jq >/dev/null || install_jq

cd /vagrant/

ANSIBLE_TARGET="${K8S_MASTERS},${K8S_NODES}" \
  ./apl-wrapper.sh ansible/target-kubernetes.yml


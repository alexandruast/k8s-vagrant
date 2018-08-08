# kube-vagrant
Vagrant Kubernetes cluster

- Setup kube-master
  ```
  sudo kubeadm init --apiserver-advertise-address=192.168.169.201 --pod-network-cidr=10.244.0.0/16
  ```

- Join kube-master from kube-node1 and kube-node2 (replace token and hash)
```
sudo kubeadm join 192.168.169.201:6443 --token ftvmz5.f1b8p4quxim4wutf --discovery-token-ca-cert-hash sha256:0d5b5e67643c335056bc64d45f01dfbc05aa28a8a0256719f61b83b9645c2ff2
```

- Run from kube-master
  ```
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

  curl -SsL https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-linux-amd64.tar.gz | tar zxv \
    && sudo mv ./linux-amd64/helm /usr/local/bin \
    && sudo chown root:root /usr/local/bin/helm \
    && rm -fr ./linux-amd64

  kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
  kubectl create clusterrolebinding serviceaccounts-cluster-admin --clusterrole=cluster-admin --group=system:serviceaccounts

  helm init
  helm repo update
  ```

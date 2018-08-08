# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["LC_ALL"] = "en_US.UTF-8"
ENV["VAGRANT_DISABLE_VBOXSYMLINKCREATE"] = "1"

box = "bento/centos-7.5"

kube_masters = [  
  {
    :hostname => "kube-master1",
    :ip => "192.168.169.201",
    :box => box,
    :memory => 2000,
    :cpus => 2
  }
]

kube_nodes = [
  {
    :hostname => "kube-node1",
    :ip => "192.168.169.211",
    :box => box,
    :memory => 3000,
    :cpus => 2
  },
  {
    :hostname => "kube-node2",
    :ip => "192.168.169.212",
    :box => box,
    :memory => 3000,
    :cpus => 2
  }
]

kube_manager = {
  :hostname => "kube-manager",
  :ip => "192.168.169.200",
  :box => box,
  :memory => 1000,
  :cpus => 1
}

Vagrant.configure(2) do |config|
  
  kube_masters.each do |machine|
    config.vm.define machine[:hostname] do |node|
      node.vm.box = machine[:box]
      node.vm.hostname = machine[:hostname]
      node.vm.provider "virtualbox" do |vb|
        vb.linked_clone = true
        vb.memory = machine[:memory]
        vb.cpus = machine[:cpus]
      end  
      node.vm.network "private_network", ip: machine[:ip]
      node.vm.provision "shell", path: "./extras/vagrant-ssh-key.sh", privileged: false
    end
  end
  
  kube_nodes.each do |machine|
    config.vm.define machine[:hostname] do |node|
      node.vm.box = machine[:box]
      node.vm.hostname = machine[:hostname]
      node.vm.provider "virtualbox" do |vb|
        vb.linked_clone = true
        vb.memory = machine[:memory]
        vb.cpus = machine[:cpus]
      end  
      node.vm.network "private_network", ip: machine[:ip]
      node.vm.provision "shell", path: "./extras/vagrant-ssh-key.sh", privileged: false
    end
  end

  config.vm.define "kube-manager" do |node|
    node.vm.box = kube_manager[:box]
    node.vm.hostname = kube_manager[:hostname]
    node.vm.provider "virtualbox" do |vb|
        vb.linked_clone = true
        vb.memory = kube_manager[:memory]
        vb.cpus = kube_manager[:cpus]
    end
    node.vm.network "private_network", ip: kube_manager[:ip]
    node.vm.provision "shell", path: "./extras/vagrant-ssh-key.sh", privileged: false
    node.vm.provision "shell" do |s|
      s.path = "./extras/kube-manager-bootstrap.sh"
      s.privileged = false
      s.args = [
        kube_masters.to_json.to_s,
        kube_nodes.to_json.to_s
      ]
    end
  end

end


# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["LC_ALL"] = "en_US.UTF-8"
ENV["VAGRANT_DISABLE_VBOXSYMLINKCREATE"] = "1"

box = "bento/centos-7.5"

kube_master = {
  :hostname => "kube-master",
  :ip => "192.168.169.201",
  :box => box,
  :memory => 1200,
  :cpus => 2
}

kube_nodes = [
  {
    :hostname => "kube-node1",
    :ip => "192.168.169.211",
    :box => box,
    :memory => 2400,
    :cpus => 2
  },
  {
    :hostname => "kube-node2",
    :ip => "192.168.169.212",
    :box => box,
    :memory => 2400,
    :cpus => 2
  }
]

Vagrant.configure(2) do |config|
  
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

  config.vm.define "kube-master" do |node|
    node.vm.box = kube_master[:box]
    node.vm.hostname = kube_master[:hostname]
    node.vm.provider "virtualbox" do |vb|
        vb.linked_clone = true
        vb.memory = kube_master[:memory]
        vb.cpus = kube_master[:cpus]
    end
    node.vm.network "private_network", ip: kube_master[:ip]
    node.vm.provision "shell", path: "./extras/vagrant-ssh-key.sh", privileged: false
    node.vm.provision "shell" do |s|
      s.path = "./extras/kube-master-bootstrap.sh"
      s.privileged = false
      s.args = [
        kube_master[:ip],
        kube_nodes.to_json.to_s
      ]
    end
  end

end


# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["LC_ALL"] = "en_US.UTF-8"
ENV["VAGRANT_DISABLE_VBOXSYMLINKCREATE"] = "1"

required_plugins = []

box = "bento/centos-7.5"
# box = "moonphase/amazonlinux2"
# box = "xianlin/rhel-7"

k8s_masters = [  
  {
    :hostname => "k8s-master1",
    :ip => "192.168.169.201",
    :box => box,
    :memory => 2000,
    :cpus => 2
  }
]

k8s_nodes = [
  {
    :hostname => "k8s-node1",
    :ip => "192.168.169.211",
    :box => box,
    :memory => 3000,
    :cpus => 2
  },
  {
    :hostname => "k8s-node2",
    :ip => "192.168.169.212",
    :box => box,
    :memory => 3000,
    :cpus => 2
  }
]

k8s_manager = {
  :hostname => "k8s-manager",
  :ip => "192.168.169.200",
  :box => box,
  :memory => 1000,
  :cpus => 1
}

missing_plugins = required_plugins.reject { |p| Vagrant.has_plugin?(p) }
unless missing_plugins.empty?
  system "vagrant plugin install #{missing_plugins.join(' ')}"
  puts "Installed new Vagrant plugins. Please re-run your last command!"
  exit 1
end

rhel_subscription_username = 'none'
rhel_subscription_password = 'none'

if box.include? "rhel"
  if ARGV[0] == "up" or ARGV[0] == "provision"
    puts "Red Hat Enterprise Linux requires RHN subscription."
    print "Press ENTER within 5 seconds to enter credentials."

    timeout_seconds = 5

    loop_a = Thread.new do
      Thread.current["key_pressed"] = false
      STDIN.noecho(&:gets).chomp
      Thread.current["key_pressed"] = true
    end

    loop_b = Thread.new do
      start_time = Time.now.to_f.to_int
      current_time = start_time
      progress_time = start_time
      while current_time - start_time < timeout_seconds do
        break if !loop_a.alive?
        current_time = Time.now.to_f.to_int
        if progress_time != current_time
          print '.'
          progress_time = current_time
        end
      end
      print "\n"
    end

    loop_b.join
    loop_a.exit
    loop_a.join

    if loop_a["key_pressed"]
      print "RHN username:"
      rhel_subscription_username = STDIN.gets.chomp
      print "RHN passsword:"
      rhel_subscription_password = STDIN.gets.chomp
    end
  end
end

bootstrap = <<SCRIPT
#!/usr/bin/env bash
set -eEo pipefail
trap 'RC=$?; echo [error] exit code $RC running $BASH_COMMAND; exit $RC' ERR
if [ -d "/home/vagrant/provision" ];then
  find /home/vagrant/provision -type f -name '*.sh' -exec chmod +x {} \\;
fi
if which subscription-manager; then
  if ! sudo subscription-manager status 2>/dev/null; then
    sudo subscription-manager register --username=#{rhel_subscription_username.strip} --password=#{rhel_subscription_password.strip} --auto-attach --force
  fi
fi
SCRIPT

Vagrant.configure(2) do |config|
  
  k8s_masters.each do |machine|
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
      node.vm.provision "shell", inline: bootstrap, privileged: false
      node.trigger.before :destroy do |trigger|
        trigger.on_error = :continue
        begin
          trigger.run_remote = { inline: "if which subscription-manager; then sudo subscription-manager unregister; fi" } if box.include? "rhel"
        rescue
          puts "If something went wrong, please remove the vm manually from https://access.redhat.com/management/subscriptions"
        end
      end
    end
  end
  
  k8s_nodes.each do |machine|
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
      node.vm.provision "shell", inline: bootstrap, privileged: false
      node.trigger.before :destroy do |trigger|
        trigger.on_error = :continue
        begin
          trigger.run_remote = { inline: "if which subscription-manager; then sudo subscription-manager unregister; fi" } if box.include? "rhel"
        rescue
          puts "If something went wrong, please remove the vm manually from https://access.redhat.com/management/subscriptions"
        end
      end
    end
  end

  config.vm.define "k8s-manager" do |node|
    node.vm.box = k8s-manager[:box]
    node.vm.hostname = k8s-manager[:hostname]
    node.vm.provider "virtualbox" do |vb|
        vb.linked_clone = true
        vb.memory = k8s-manager[:memory]
        vb.cpus = k8s-manager[:cpus]
    end
    node.vm.network "private_network", ip: k8s-manager[:ip]
    node.vm.provision "shell", path: "./extras/vagrant-ssh-key.sh", privileged: false
    node.vm.provision "shell", inline: bootstrap, privileged: false
    node.vm.provision "shell" do |s|
      s.path = "./extras/k8s-manager-bootstrap.sh"
      s.privileged = false
      s.args = [
        k8s-masters.to_json.to_s,
        k8s-nodes.to_json.to_s
      ]
    end
    node.trigger.before :destroy do |trigger|
      trigger.on_error = :continue
      begin
        trigger.run_remote = { inline: "if which subscription-manager; then sudo subscription-manager unregister; fi" } if box.include? "rhel"
      rescue
        puts "If something went wrong, please remove the vm manually from https://access.redhat.com/management/subscriptions"
      end
    end
  end

end


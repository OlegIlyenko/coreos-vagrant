# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'fileutils'
require 'erb'
require 'net/http'
require 'uri'

Vagrant.require_version ">= 1.6.0"

CONFIG = File.join(File.dirname(__FILE__), "config.rb")

# Defaults for config options defined in CONFIG
$num_instances = 0
$update_channel = "alpha"
$enable_serial_logging = false
$vb_gui = false
$vb_memory = 1024
$vb_cpus = 1

# Attempt to apply the deprecated environment variable NUM_INSTANCES to
# $num_instances while allowing config.rb to override it
if ENV["NUM_INSTANCES"].to_i > 0 && ENV["NUM_INSTANCES"]
  $num_instances = ENV["NUM_INSTANCES"].to_i
end

if File.exist?(CONFIG)
  require CONFIG
end

def render_file file, cfg
  target_file = file.gsub(/\.erb$/, '') + ".tmp"
  File.open(target_file, 'w') do |f|
    f.write ERB.new(File.read(file)).result(binding)
  end

  target_file
end

def create_vm config, name, user_data, ports, idx, cfg
  cloud_config_path = render_file(File.join(File.dirname(__FILE__), user_data), cfg)

  config.vm.define vm_name = name do |config|
    config.vm.hostname = vm_name

    if $enable_serial_logging
      logdir = File.join(File.dirname(__FILE__), "log")
      FileUtils.mkdir_p(logdir)

      serialFile = File.join(logdir, "%s-serial.txt" % vm_name)
      FileUtils.touch(serialFile)

      config.vm.provider :vmware_fusion do |v, override|
        v.vmx["serial0.present"] = "TRUE"
        v.vmx["serial0.fileType"] = "file"
        v.vmx["serial0.fileName"] = serialFile
        v.vmx["serial0.tryNoRxLoss"] = "FALSE"
      end

      config.vm.provider :virtualbox do |vb, override|
        vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
        vb.customize ["modifyvm", :id, "--uartmode1", serialFile]
      end
    end

    ports.each do |port|
      config.vm.network "forwarded_port", guest: port, host: port, auto_correct: true
    end

    config.vm.provider :vmware_fusion do |vb|
      vb.gui = $vb_gui
    end

    config.vm.provider :virtualbox do |vb|
      vb.gui = $vb_gui
      vb.memory = $vb_memory
      vb.cpus = $vb_cpus
    end

    ip = cfg[:ips][idx - 1]
    config.vm.network :private_network, ip: ip

    if File.exist?(cloud_config_path)
      #config.vm.provision :shell, path: "install-kubernetes.sh", :privileged => true
      config.vm.provision :file, :source => "#{cloud_config_path}", :destination => "/tmp/vagrantfile-user-data"
      config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
    end
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = "coreos-%s" % $update_channel
  config.vm.box_version = ">= 308.0.1"
  config.vm.box_url = "http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json" % $update_channel

  config.vm.provider :vmware_fusion do |vb, override|
    override.vm.box_url = "http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant_vmware_fusion.json" % $update_channel
  end

  config.vm.provider :virtualbox do |v|
    # On VirtualBox, we don't have guest additions or a functional vboxsf
    # in CoreOS, so tell Vagrant that so it can be smarter.
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  cfg = {ips: (1..$num_instances + 1).map {|i| "172.17.8.#{i + 100}"}}

  create_vm config, "master", "master.yml.erb", [8080], 1, cfg

  if $num_instances > 0
    (1..$num_instances).each do |i|
      create_vm config, "minion-#{i}", "minion.yml.erb", [], i + 1, cfg
    end
  end
end

# -*- mode: ruby -*-
# vi: set ft=ruby :

# Use Vagrant.configure version 2 to configure this VM
Vagrant.configure(2) do |config|
  # The base vagrant box to use for this VM. We are going to use Ubuntu 14.04
  config.vm.box = "puphpet/ubuntu1404-x64"

  # Let's call the host something contextual
  config.vm.hostname = "tidepool-vm"

  # Port forwards for Blip, Shoreline and Chrome Uploader
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.network "forwarded_port", guest: 8009, host: 8009
  config.vm.network "forwarded_port", guest: 9122, host: 9122
  config.vm.network "forwarded_port", guest: 3004, host: 3004

  # Let's make the VM accessible via a static local IP too
  config.vm.network "private_network", ip: "192.168.33.100"

  # Share the tidepool parent directory and mount it in the VMs file system
  config.vm.synced_folder "../", "/tidepool"

  # Set the memory available and number of cpus when using VirtualBox
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end
  
  # Set the memory available when using Paralells
  config.vm.provider "parallels" do |v|
    v.memory = "2048"
  end

  # Provision the VM using setup_vagrant.sh - this will install all the 
  # required dependencies
  config.vm.provision :shell, :path => "setup_vagrant.sh"
end

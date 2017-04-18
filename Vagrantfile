# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# == BSD2 LICENSE ==
# Copyright (c) 2017, Tidepool Project
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the associated License, which is identical to the BSD 2-Clause
# License as published by the Open Source Initiative at opensource.org.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the License for more details.
#
# You should have received a copy of the License along with this program; if
# not, you can obtain one from Tidepool Project at tidepool.org.
# == BSD2 LICENSE ==
#

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
  config.vm.network "forwarded_port", guest: 8077, host: 8077 # dataservices
  config.vm.network "forwarded_port", guest: 8078, host: 8078 # userservices

  # Let's make the VM accessible via a static local IP too
  config.vm.network "private_network", ip: "192.168.33.100"

  # Share the tidepool parent directory and mount it in the VMs file system
  config.vm.synced_folder "../", "/tidepool", fsnotify: true

  # Set the memory available and number of cpus when using VirtualBox
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  # Set the memory available when using Paralells
  config.vm.provider "parallels" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
    vb.update_guest_tools = true
  end

  # Get rid of the "default: stdin: is not a tty" errors in Vagrant
  # From https://github.com/Varying-Vagrant-Vagrants/VVV/issues/517#issuecomment-212419167
  config.vm.provision "fix-no-tty", type: "shell" do |s|
    s.privileged = false
    s.inline = "sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
  end

  # Provision the VM using setup_vagrant.sh - this will install all the
  # required dependencies
  config.vm.provision :shell, :path => "setup_vagrant.sh"
end

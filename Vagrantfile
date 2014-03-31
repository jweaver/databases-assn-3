# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.host_name = "oracle"

  config.vm.network :hostonly, "192.168.33.10"
  #  Doesn't work for some reason?  config.vm.synced_folder "/home/jw/Desktop/HW-2-databases/sql-files", "/sql-files"

  #Enable DNS behind NAT
  config.vm.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]

  #Port forward Oracle port
  config.vm.forward_port 1521, 1521

  config.vm.provision :puppet,
  :module_path => "modules",
  :options => "--verbose --trace" do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file  = "base.pp"
  end

  config.vm.customize ["modifyvm", :id,
                       "--name", "oracle",
                       "--memory", "3048"]
end

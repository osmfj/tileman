# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.vm.provision :shell, :path => "bootstrap.sh"

  ## If you want to load test db and run test automatically, 
  ## enable a part of commented out.
  # config.vm.provision :shell, :path => "test/load.sh"
  # config.vm.provision :shell, :path => "test/run.sh"

  # please run:
  #  $ vagrant init
  #  $ vagrant box add precise64 <URL>
  #  $ vagrant up --provider=kvm  # if you use kvm
  #
  config.vm.provider :virtualbox do |vb, override|
   override.vm.box     = "precise64"
   override.vm.box_url = "http://files.vagrantup.com/precise64.box"
  end
  
  config.vm.provider :kvm do |kvm, override| 
    kvm.gui = true
    override.vm.box     = "precise64"
    override.vm.box_url = "https://s3-ap-northeast-1.amazonaws.com/miurahr-public/precise64-kvm.box"
  end

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. 
  # config.vm.network :forwarded_port, guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network :private_network, ip: "192.168.33.10"

end

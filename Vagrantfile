#
# CORL Vagrant development environment
#-------------------------------------------------------------------------------

Vagrant.configure('2') do |config|

  synced_folders = lambda do |node|
    node.vm.synced_folder '.', "/usr/local/rvm/gems/ruby-2.1.5/gems/corl-#{File.read('VERSION')}", {
      :type           => 'rsync',
      :owner          => 'root',
      :group          => 'root',
      :rsync__exclude => [ '.git/', 'share/', 'pkg/' ],
      :rsync__auto    => true,
      :rsync__chown   => true,
      :rsync__args    => [ '--verbose', "--rsync-path='sudo rsync'", '--archive', '--delete', '-z' ],
      :create         => true
    }
    node.vm.synced_folder 'share/home', "/home/vagrant", {
      :type          => 'rsync',
      :owner         => 'vagrant',
      :group         => 'vagrant',
      :rsync__auto   => true,
      :rsync__chown  => true,
      :rsync__args   => [ '--verbose', '--archive', '-z' ],
      :create        => true
    }
  end

  provisioners = lambda do |node|
    # CORL bootstrap
    node.vm.provision :shell, path: "vagrant/corl.sh"
  end

  #
  # Default CORL development machine
  #
  # - should work on any platform Vagrant supports
  #
  config.vm.define :corl do |node|
    # One directional pushes
    synced_folders.call node

    node.vm.provider :virtualbox do |provider, override|
      override.vm.box = "coralnexus/vagrant-ubuntu"

      override.vm.network :private_network, :ip => "172.100.100.92"

      # Bi-directional synchronization
      override.vm.synced_folder "share/network", "/var/corl"
    end

    # Provisioning
    provisioners.call node
  end

  #
  # Linux specific CORL development machine
  #
  # - meant for platforms that support Docker and have it installed and running
  # - creates development related container on local machine through Docker daemon
  # - Docker must be running on the system (daemonized)
  #
  config.vm.define :corl_linux do |node|
    # One directional pushes
    synced_folders.call node

    node.vm.provider :docker do |provider|
      provider.cmd           = [ "/sbin/my_init" ]
      provider.image         = "coralnexus/vagrant-ubuntu"
      provider.has_ssh       = true
      provider.force_host_vm = false
      provider.create_args   = [ "--hostname='corl_linux'" ]

      # Bi-directional synchronization
      provider.volumes = [ "#{File.dirname(__FILE__)}/share/network:/var/corl" ]
    end

    # Provisioning
    provisioners.call node
  end
end

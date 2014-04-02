
module VagrantPlugins
module CORL
module Provisioner
class CORL < ::Vagrant.plugin("2", :provisioner)
 
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
 
  def initialize(machine, config)
    super
  end
  
  #-----------------------------------------------------------------------------
  # Operations

  def configure(root_config)
  end
  
  #---

  def provision
    @machine.communicate.tap do |comm|
      network_path = config.network_path
      network      = config.network
      node         = config.node
      
      # Make sure the CORL network directory is properly set up
      comm.sudo("rm -Rf #{network_path}")
      comm.sudo("ln -s /vagrant #{network_path}")
      
      # Make sure the CORL SSH keys are allowed
      if node.public_key
        ssh_key = ::CORL::Util::Disk.read(node.public_key)
        
        if ssh_key && ! ssh_key.empty?
          comm.execute("echo '#{ssh_key}' > \$HOME/.ssh/authorized_keys")
          node.set_cache_setting(:use_private_key, true)
        end
      end
    end
  end
end
end
end
end

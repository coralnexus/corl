
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
      unless ::CORL::Vagrant.command
        # Hackish solution to ensure our code has access to Vagrant machines.
        # This serves as a Vagrant VM manager.
        ::CORL::Vagrant.command = Command::Launcher.new([], @machine.env)
      end
    
      network = config.network
      node    = config.node
      
      if network && node
        # Provision the server
        success = true
        #success = network.init_node(node, clean(::CORL.config(:vagrant_node_init, {
        #  :force             => config.force_updates,
        #  :home              => config.user_home,
        #  :home_env_var      => config.user_home_env_var,
        #  :root_user         => config.root_user,
        #  :root_home         => config.root_home,
        #  :bootstrap         => config.bootstrap,
        #  :bootstrap_path    => config.bootstrap_path,
        #  :bootstrap_glob    => config.bootstrap_glob,
        #  :bootstrap_init    => config.bootstrap_init,
        #  :auth_files        => config.auth_files,
        #  :seed              => config.seed,
        #  :project_reference => config.project_reference,
        #  :project_branch    => config.project_branch,
        #  :provision         => config.provision,
        #  :dry_run           => config.dry_run
        #}).export))
        
        node.ui.warn("CORL provisioner failed") unless success
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def clean(options)
    options.keys.each do |key|
      value = options[key]
      if value.nil?
        options.delete(key)
      end  
    end
    options  
  end
  protected :clean
end
end
end
end

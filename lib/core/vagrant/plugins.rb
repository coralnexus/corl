
if Vagrant::VERSION < "1.2.0"
  raise "The Vagrant CORL plugin is only compatible with Vagrant 1.2+"
end

module VagrantPlugins
module CORL
class Plugin < ::Vagrant.plugin('2')
  
  name '[C]luster [O]rchestration and [R]esearch [L]ibrary'
  description 'The `corl` plugin provides an easy way to develop and test CORL networks locally from within Vagrant.'
  
  @@directory       = File.dirname(__FILE__) 
  @@action_dir      = File.join(@@directory, 'actions')   
  @@command_dir     = File.join(@@directory, 'commands')
  @@provisioner_dir = File.join(@@directory, 'provisioner')
  
  #--- 
  
  nucleon_require(@@directory, :config)
  nucleon_require(@@directory, :action)
  nucleon_require(@@command_dir, :launcher)  

  # Commands (only one, which launches Nucleon actions)
  command(:corl) do    
    Command::Launcher # Meta command for action launcher
  end
      
  # Provisioner (we handle provisioning internally)
  config(:corl, :provisioner) do
    nucleon_require(@@provisioner_dir, :config)
    Config::CORL
  end
  provisioner(:corl) do
    nucleon_require(@@provisioner_dir, :provisioner)
    Provisioner::CORL
  end
  
  # Action hooks
  action_hook 'init-keys', :machine_action_up do |hook|
    nucleon_require(@@action_dir, :init_keys)
    hook.after Vagrant::Action::Builtin::WaitForCommunicator, Action::InitKeys
  end
  
  if ENV['CORL_LINK_NETWORK']
    action_hook 'link-network', :machine_action_up do |hook|
      nucleon_require(@@action_dir, :link_network)
      hook.after Action::InitKeys, Action::LinkNetwork
    end
  end
  
  action_hook 'delete-cache', :machine_action_destroy do |hook|
    nucleon_require(@@action_dir, :delete_cache)
    hook.after Vagrant::Action::Builtin::ProvisionerCleanup, Action::DeleteCache
  end
end
end
end

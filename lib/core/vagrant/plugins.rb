
if Vagrant::VERSION < "1.2.0"
  raise "The Vagrant CORL plugin is only compatible with Vagrant 1.2+"
end

module VagrantPlugins
module CORL
class Plugin < ::Vagrant.plugin('2')
  
  name '[C]oral [O]rchestration and [R]esearch [L]ibrary'
  description 'The `corl` plugin provides an easy way to develop and test CORL networks locally from within Vagrant.'
      
  @@command_dir     = File.join(File.dirname(__FILE__), 'commands')
  @@provisioner_dir = File.join(File.dirname(__FILE__), 'provisioner') 

  # Commands (only one, which launches Nucleon actions)
  command(:corl) do
    nucleon_require(@@command_dir, :launcher)
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
end
end
end

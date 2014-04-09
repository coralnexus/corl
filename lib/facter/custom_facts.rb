
begin
  require 'corl'

  # Load network if it exists
  if CORL.admin?
    network_path   = Facter.value("corl_network")
    network_config = CORL.config(:network, { :directory => network_path })    
    network        = CORL.network(network_path, network_config, :default)

    if network && node = network.local_node
      Facter.add(:corl_provider) do
        setcode do
          node.plugin_provider
        end  
      end
      
      corl_facts = CORL::Util::Data.merge([ {
        :corl_identity    => "test",
        :corl_stage       => "maintain",
        :corl_type        => "core",
        :corl_environment => "development"
      }, node[:facts] ])
      
      CORL::Util::Data.hash(corl_facts).each do |name, value|    
        Facter.add(name) do
          confine :kernel => :linux # TODO: Extend this to work with more systems
    
          setcode do
            value
          end
        end
      end
    end
  end
rescue # Prevent abortions if does not exist
end


begin
  require 'corl'

  # Load network if it exists
  network_path   = Facter.value("corl_network")
  network_config = CORL.config(:network, { :directory => network_path })
    
  if CORL.admin? || network_path != network_config[:directory]
    network = CORL.network(network_config[:directory], network_config, :default)
    
    if network && node = network.local_node
      Facter.add(:corl_provider) do
        setcode do
          node.plugin_provider.to_s
        end  
      end
      
      corl_facts = CORL::Util::Data.merge([ {
        :corl_identity    => "test",
        :corl_stage       => "initialize",
        :corl_type        => "unknown",
        :corl_environment => "development"
      }, node.custom_facts ])
      
      CORL::Util::Data.hash(corl_facts).each do |name, value|    
        Facter.add(name) do
          setcode do
            value
          end
        end
      end
    end
  end
rescue # Prevent abortions if does not exist
end


begin
  require 'corl'

  # Load network if it exists
  network_path   = Facter.value("corl_network")
  network_config = CORL.config(:network, { :directory => network_path, :name => network_path })    
  network        = CORL.network(CORL.sha1(network_config), network_config, :default)

  if network && node = network.local_node
    CORL::Util::Data.hash(node[:facts]).each do |name, value|    
      Facter.add(name) do
        confine :kernel => :linux # TODO: Extend this to work with more systems
    
        setcode do
          value
        end
      end
    end
  end
rescue # Prevent abortions if does not exist
end

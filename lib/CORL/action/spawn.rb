
module CORL
module Action
class Spawn < Plugin::CloudAction
  
  include Mixin::Action::Keypair
 
  #----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :network_failure,
            :key_failure,
            :node_create_failure
      
      register :groups, :array, []      
      register :region, :str, nil
      register :machine_type, :str, nil
      register :image, :str, nil
      register :user, :str, nil     
      register :hostnames, :array, nil
        
      keypair_config
      
      config.defaults(CORL.action_config(:bootstrap))
      config.defaults(CORL.action_config(:seed))
    end
  end
  
  #---
  
  def ignore
    node_ignore - [ :parallel, :node_provider ] + [ :bootstrap_nodes ]
  end
  
  def arguments
    [ :node_provider, :image, :hostnames ]
  end
  
  #-----------------------------------------------------------------------------
  # Operations
 
  def execute
    super do |node, network|
      if network
        if keypair && keypair_clean
          hostnames     = []
          results       = []
          node_provider = settings.delete(:node_provider)
          
          if CORL.vagrant? && ! CORL.loaded_plugins(:node).keys.include?(node_provider.to_sym)
            settings[:machine_type] = node_provider
            settings[:user]         = :vagrant unless settings[:user]            
            node_provider           = :vagrant
          end
          unless settings[:user]
            settings[:user] = :root  
          end
          
          info('corl.actions.spawn.start', { :node_provider => node_provider }) 
          
          settings.delete(:hostnames).each do |hostname|
            hostnames << extract_hostnames(hostname)
          end
          hostnames.flatten.each do |hostname|
            if hostname.is_a?(Hash)
              settings[:public_ip] = hostname[:ip]
              hostname             = hostname[:hostname]  
            end
            
            if settings[:parallel]
              results << network.future.add_node(node_provider, hostname, settings)
            else
              results << network.add_node(node_provider, hostname, settings)    
            end
          end
          results       = results.map { |future| future.value } if settings[:parallel]                  
          myself.status = code.batch_error if results.include?(false)
        else
          myself.status = code.key_failure  
        end        
      else
        myself.status = code.network_failure    
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def extract_hostnames(hostname)
    hostnames = []
    
    if hostname.match(/([^\[]+)\[([^\]]+)\](.*)/)
      before = $1
      extra  = $2.strip
      after  = $3
      
      if extra.match(/\-/)
        low, high = extra.split(/\s*\-\s*/)
        range     = Range.new(low, high)
      
        range.each do |item|
          hostnames << "#{before}#{item}#{after}"  
        end
        
      elsif extra.match(/\d+\.\d+\.\d+\.\d+/)
        hostnames = [ { :hostname => "#{before}#{after}", :ip => extra } ]  
      end
    else
      hostnames = [ hostname ]
    end
    hostnames
  end
  protected :extract_hostnames
end
end
end

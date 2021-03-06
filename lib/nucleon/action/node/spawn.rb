
module Nucleon
module Action
module Node
class Spawn < Nucleon.plugin_class(:nucleon, :cloud_action)
  
  include Mixin::Action::Keypair
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :spawn, 635)
  end
 
  #----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :key_failure,
            :node_create_failure
      
      register_bool :bootstrap, true
      register_bool :provision, false
      
      register_array :hostnames, nil
      register_array :groups
           
      register_str :region, nil
      register_str :machine_type, nil
      register_str :image, nil
      register_str :user, nil     
              
      keypair_config
      
      config.defaults(CORL.action_config(:node_bootstrap))
      config.defaults(CORL.action_config(:node_seed))
    end
  end
  
  def node_config
    super
    config[:node_provider].default = nil
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
    super do |node|
      ensure_network do
        if keypair && keypair_clean
          hostnames     = []
          results       = []
          node_provider = settings.delete(:node_provider)
          is_parallel   = CORL.parallel? && settings[:parallel]
          
          if CORL.vagrant? && ! CORL.loaded_plugins(:CORL, :node).keys.include?(node_provider.to_sym)
            settings[:machine_type] = node_provider
            settings[:user]         = :vagrant unless settings[:user]            
            node_provider           = :vagrant
          end
          unless settings[:user]
            settings[:user] = :root  
          end
          
          info('start', { :node_provider => node_provider }) 
          
          settings.delete(:hostnames).each do |hostname|
            hostnames << extract_hostnames(hostname)
          end
          hostnames.flatten.each do |hostname|
            if hostname.is_a?(Hash)
              settings[:public_ip] = hostname[:ip]
              hostname             = hostname[:hostname]  
            end
            
            if is_parallel
              results << network.future.add_node(node_provider, hostname, settings.export)
            else
              results << network.add_node(node_provider, hostname, settings.export)    
            end
          end
          results       = results.map { |future| future.value } if is_parallel                
          myself.status = code.batch_error if results.include?(false)
        else
          myself.status = code.key_failure  
        end        
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
end

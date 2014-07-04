
module Nucleon
module Action
module Node
class Cache < CORL.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :cache, 575)
  end
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      register :name, :str, ''
      register :value, :str, ''
      
      register :delete, :bool, false
      register :clear, :bool, false
      
      register :json, :bool, false
    end
  end
  
  #---
  
  def arguments
    [ :name, :value ]
  end

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      ensure_node(node) do
        delete_setting = settings.delete(:delete, false)
        clear_settings = settings.delete(:clear, false)
        use_json       = settings.delete(:json, false)
        
        if clear_settings
          node.clear_cache
        else
          if settings[:name].empty?
            myself.result = node.cache_setting([], {}, :hash)
            $stderr.puts Util::Data.to_json(result, true)
            
          else
            settings[:name] = settings[:name].split('.')
            
            if delete_setting
              node.delete_cache_setting(settings[:name])
                
            elsif ! settings[:value].empty?
              settings[:value] = Util::Data.parse_json(settings[:value]) if use_json
              myself.result = settings[:value]           
              node.set_cache_setting(settings[:name], settings[:value])
              
            else
              myself.result = node.cache_setting(settings[:name])
              $stderr.puts Util::Data.to_json(result, true)
            end
          end
        end 
      end
    end
  end
end
end
end
end

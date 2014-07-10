
module Nucleon
module Action
module Plugin
class List < CORL.plugin_class(:nucleon, :cloud_action)
   
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:plugin, :list, 15)
  end
  
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      
    end
  end
  
  #---
  
  def arguments
    []
  end
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      ensure_network(network) do
        last_namespace   = nil
        last_plugin_type = nil
        
        Nucleon.loaded_plugins.each do |namespace, plugins|
          info("------------------------------------------------------", { :i18n => false, :prefix => false })
          info(" Namespace: #{purple(namespace)}", { :i18n => false, :prefix => false })
          info("\n", { :i18n => false, :prefix => false })
          
          provider_info = {}
          max_width     = 10
                    
          plugins.each do |type, providers|
            info("    Plugin type: #{blue(type)}", { :i18n => false, :prefix => false })
            info("      Providers:", { :i18n => false, :prefix => false }) 
            
            providers.keys.each do |name|
              width     = name.to_s.size
              max_width = width if width > max_width
            end
            
            providers.each do |provider, plugin_info|
              info("        #{sprintf("%-#{max_width + 10}s", green(provider))}  -  #{yellow(plugin_info[:file])}", { :i18n => false, :prefix => false }) 
            end
            info("\n", { :i18n => false, :prefix => false })
            last_plugin_type = type
          end
          last_namespace = namespace
        end     
      end
    end
  end
end
end
end
end

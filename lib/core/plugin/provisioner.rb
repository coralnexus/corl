
module Nucleon
module Plugin
class Provisioner < CORL.plugin_class(:base)

  #-----------------------------------------------------------------------------
  # Provisioner plugin interface
  
  def normalize(reload)
    super
  end
  
  #---

  def initialized?(options = {})
  end
     
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers

  network_settings :provisioner

  #-----------------------------------------------------------------------------
  
  def profiles
    array(myself[:profiles])
  end
  
  #-----------------------------------------------------------------------------
  # Provisioner operations
 
  def register
  end
  
  #---
  
  def build(build_directory)
    FileUtils.mkdir(build_directory)
    dbg("Building into the build directory: #{build_directory}")
  end
  
  #---
  
  def lookup(property, default = nil, options = {})
  end
  
  #--
  
  def import(files)
  end
  
  #---
  
  def include(resource_name, properties, options = {})
  end
  
  #---
  
  def provision(options = {})
  end
       
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.build_info(type, data)  
    data = data.split(/\s*,\s*/) if data.is_a?(String)
    super(type, data)
  end
  
  #---
   
  def self.translate(data)
    options = super(data)
    
    case data        
    when String
      options = { :profiles => array(data) }
    when Hash
      options = data
    end
    
    if options.has_key?(:profiles)
      if matches = translate_reference(options[:profiles])
        options[:provider] = matches[:provider]
        options[:profiles] = matches[:profiles]
        
        logger.debug("Translating provisioner options: #{options.inspect}")  
      end
    end
    options
  end
  
  #---
  
  def self.translate_reference(reference)
    # ex: puppetnode:::profile::something,profile::else
    if reference && reference.match(/^\s*([a-zA-Z0-9_-]+):::([^\s]+)\s*$/)
      provider = $1
      profiles = $2
      
      logger.debug("Translating provisioner reference: #{provider} #{profiles}")
      
      info = {
        :provider => provider,
        :profiles => profiles.split(/\s*,\s*/)
      }
      
      logger.debug("Project reference info: #{info.inspect}")
      return info
    end
    nil
  end
  
  #---
  
  def translate_reference(reference)
    myself.class.translate_reference(reference)
  end
end
end
end


module Nucleon
module Plugin
class Provisioner < CORL.plugin_class(:base)
  
  include Celluloid
 
  #-----------------------------------------------------------------------------
  # Provisioner plugin interface
  
  def normalize(reload)
    super
    yield if block_given?
    register
  end
  
  #---

  def initialized?(options = {})
  end
     
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers

  network_settings :provisioner

  #---
  
  def id
    plugin_name.gsub('::', '_').to_sym
  end
  
  #---
  
  def directory=directory
    myself[:directory] = directory
  end
  
  def directory
    myself[:directory]
  end
  
  #---
  
  def gateway=gateway
    myself[:gateway] = gateway
  end
  
  def gateway
    myself[:gateway]
  end
  
  #---
  
  def packages=packages
    myself[:packages] = hash(packages)
  end
  
  def packages
    hash(myself[:packages])
  end
  
  #---
  
  def profiles=profiles
    myself[:profiles] = array(profiles)
  end
  
  def profiles
    array(myself[:profiles])
  end
  
  #-----------------------------------------------------------------------------
  # Provisioner operations
 
  def register
    # Implement in providers
  end
  
  #---
  
  def build(build_directory)
    locations = {}
    
    init_location = lambda do |name, ext = '', base_directory = nil|
      name = name.to_sym
      
      base_directory = directory if base_directory.nil?
          
      # Create directory
      locations[name] = File.join(locations[:build], name.to_s)    
      FileUtils.mkdir_p(locations[name])
     
      # Copy directory contents
      unless ext.nil?
        ext             = ! ext.to_s.empty? ? ".#{ext}" : ''
        local_directory = File.join(base_directory, name.to_s)
    
        if File.directory?(local_directory)  
          unless Dir.glob(File.join(local_directory, "*#{ext}")).empty?
            locations[name] = File.join(locations[:build], name.to_s)
            FileUtils.cp_r(local_directory, locations[:build])
          end
        end
        
        # Copy gateway file
        gateway_file = File.join(base_directory, "#{name}#{ext}")
      
        if File.exists?(gateway_file)
          FileUtils.cp(gateway_file, locations[:build])  
        end
      end  
    end
    
    init_package = lambda do |name, reference|
      package_directory = File.join(locations[:packages], name.to_s)
        
      project = CORL.configuration(extended_config(:package, {
        :directory => package_directory,
        :url       => reference
      }))
      unless project
        success = false
        break
      end
      
      dbg(project.export, 'exported package contents')    
    end
    
    locations[:build] = File.join(build_directory.to_s, id.to_s)    
    FileUtils.mkdir_p(locations[:build])
    
    init_location.call(:packages, nil)
    
    # Build packages
    packages.each do |name, reference|
      init_package.call(name, reference)
    end
      
    yield(locations, init_location) if block_given?
    
    myself[:build_locations] = locations
  end
  
  #---
  
  def lookup(property, default = nil, options = {})
    # Implement in providers
  end
  
  #--
  
  def import(files)
    # Implement in providers
  end
  
  #---
  
  def include(resource_name, properties, options = {})
    # Implement in providers
  end
  
  #---
  
  def provision(options = {})
    # Implement in providers
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

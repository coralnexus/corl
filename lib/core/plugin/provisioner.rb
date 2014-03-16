
module Nucleon
module Plugin
class Provisioner < CORL.plugin_class(:base)
  
  include Celluloid
 
  #-----------------------------------------------------------------------------
  # Provisioner plugin interface
  
  def normalize(reload)
    super
    yield if block_given?
  end
  
  #-----------------------------------------------------------------------------
  # Checks

  def initialized?(options = {})
  end
  
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers

  network_settings :provisioner

  #---
  
  def id(name = nil)
    name = plugin_name if name.nil?
    name.to_s.gsub('::', '_').to_sym
  end
  
  #---
  
  def directory=directory
    myself[:directory] = directory
  end
  
  def directory
    myself[:directory]
  end
  
  #---
  
  def build_directory
    File.join(network.build_directory, plugin_provider.to_s)
  end
  
  #---
  
  def gateway=gateway
    myself[:gateway] = gateway
  end
  
  def gateway
    myself[:gateway]
  end
  
  #---
  
  def packages
    hash(myself[:packages])
  end
  
  #---
  
  def profiles
    hash(myself[:profiles])
  end
  
  def find_profiles(reset = false)
    allowed_profiles = []  
    build_info(reset).each do |package_name, package_info|
      hash(package_info[:profiles]).each do |profile_name, profile_info|
        allowed_profiles << concatenate([ package_name, 'profile', profile_name ])
      end
    end
    profiles.each do |profile_name, profile_info|
      allowed_profiles << concatenate([ plugin_name, 'profile', profile_name ])
    end
    allowed_profiles  
  end
  protected :find_profiles
  
  #---
  
  def supported_profiles(profile_names = nil)
    found    = []    
    profiles = build_profiles
    
    if profile_names.nil?
      found = profiles  
    else
      profile_names.each do |name|
        name = name.to_s
        if profiles.include?(name)
          found << name
        end
      end
    end
    found.empty? ? false : found
  end
     
  #---
  
  def build_locations(reset = false)
    locations = hash(myself[:build_locations])
    build if reset || locations.empty?
    myself[:build_locations]
  end
  
  #---
  
  def build_info(reset = false)
    info = hash(myself[:build_info])
    build if reset || info.empty?
    myself[:build_info]
  end
  
  #---
  
  def build_profiles(reset = false)
    profiles = array(myself[:build_profiles])
    build if reset || profiles.empty?
    myself[:build_profiles]
  end
  
  #-----------------------------------------------------------------------------
  # Provisioner operations
 
  def register(options = {})
    # Implement in providers
  end
  
  #---
  
  def build(options = {})
    config = Config.ensure(options)
    
    locations    = Config.new({ :package => {} })
    package_info = Config.new
    
    init_location = lambda do |name, ext = '', base_directory = nil|
      name           = name.to_sym      
      base_directory = directory if base_directory.nil?
      build_base     = build_directory
          
      # Create directory
      locations[name] = File.join(locations[:build], name.to_s)        
      FileUtils.mkdir_p(File.join(build_base, locations[name]))
     
      # Copy directory contents
      unless ext.nil?
        ext             = ! ext.to_s.empty? ? ".#{ext}" : ''
        local_directory = File.join(base_directory, name.to_s)
        
        if File.directory?(local_directory)  
          unless Dir.glob(File.join(local_directory, "*#{ext}")).empty?            
            FileUtils.cp_r(local_directory, File.join(build_base, locations[:build]))
          end
        end
        
        # Copy gateway file
        gateway_file = File.join(base_directory, "#{name}#{ext}")
      
        if File.exists?(gateway_file)
          FileUtils.cp(gateway_file, File.join(build_base, locations[:build]))
        end
      end  
    end
    
    init_package = lambda do |name, reference|
      package_directory = File.join(locations[:packages], id(name).to_s)
        
      project = CORL.configuration(extended_config(:package, {
        :directory => File.join(build_directory, package_directory),
        :url       => reference,
        :create    => true
      }))
      raise unless project
      
      package_info.import(project.export)
      locations[:package][name] = package_directory
      
      if project.get([ :provisioners, plugin_provider ], false)
        project.get_hash([ :provisioners, plugin_provider ]).each do |prov_name, info|
          if info.has_key?(:packages)
            info[:packages].each do |sub_name, sub_reference|
              init_package.call(sub_name, sub_reference)
            end
          end
        end
      end
    end
    
    locations[:build]     = id.to_s
    local_build_directory = File.join(build_directory, locations[:build])   
    
    FileUtils.rm_rf(local_build_directory)
    FileUtils.mkdir_p(local_build_directory)
    
    init_location.call(:packages, nil)
    
    # Build packages
    packages.each do |name, reference|
      init_package.call(name, reference)
    end
     
    yield(locations, package_info, init_location) if block_given?
    
    myself[:build_locations] = locations.export
    myself[:build_info]      = package_info.get([ :provisioners, plugin_provider ])
    myself[:build_profiles]  = find_profiles
    
    network.save(config.import({
      :commit      => true,
      :allow_empty => true, 
      :message     => config.get(:message, "Built #{plugin_provider} provisioner #{plugin_name}"),
      :remote      => config.get(:remote, :edit)
    }))
  end
  
  #---
  
  def lookup(property, default = nil, options = {})
    # Implement in providers
  end
   
  #---
  
  def provision(profiles, options = {})
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
    # ex: puppetnode:::profile::something,profile::somethingelse
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
  
  #---
  
  def concatenate(components, capitalize = false, joiner = '::')
    if components.is_a?(Array)
      components = components.collect do |str|
        str.to_s.split('__')  
      end.flatten
    else
      components = [ components.to_s ]
    end
    
    if capitalize
      name = components.collect {|str| str.capitalize }.join(joiner)
    else
      name = components.join(joiner)
    end
    name
  end
end
end
end

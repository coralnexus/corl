
module Nucleon
module Plugin
class Provisioner < CORL.plugin_class(:base)
  
  include Parallel
  
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
    File.join(network.directory, myself[:directory])
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
    locations = cache_setting(:build_locations, {}, :hash)
    build if reset || locations.empty?
    cache_setting(:build_locations, {}, :hash)
  end
  
  #---
  
  def build_info(reset = false)
    info = cache_setting(:build_info, {}, :hash)
    build if reset || info.empty?
    cache_setting(:build_info, {}, :hash)
  end
  
  #---
  
  def build_profiles(reset = false)
    profiles = cache_setting(:build_profiles, [], :array)
    build if reset || profiles.empty?
    cache_setting(:build_profiles, [], :array)
  end
  
  #-----------------------------------------------------------------------------
  # Provisioner operations
 
  def register(options = {})
    # Implement in providers
  end
  
  #---
  
  def build(options = {})
    config       = Config.ensure(options)
    success      = true    
    locations    = Config.new({ :build => id.to_s, :package => {} })
    package_info = Config.new
    
    init_package = lambda do |name, reference|
      package_directory = File.join(locations[:build], 'packages', id(name).to_s)
      package_success   = true
      
      ui.info("Building package #{blue(name)} at #{purple(reference)} into #{green(package_directory)}")
      
      full_package_directory = File.join(build_directory, package_directory)
        
      project = CORL.configuration(extended_config(:package, {
        :directory => full_package_directory,
        :url       => reference,
        :create    => File.directory?(full_package_directory) ? false : true
      }))
      unless project
        ui.warn("Project #{cyan(name)} failed to initialize")
        package_success = false
      end
      
      if package_success
        package_info.import(project.export)
        locations[:package][name] = package_directory
      
        if project.get([ :provisioners, plugin_provider ], false)
          project.get_hash([ :provisioners, plugin_provider ]).each do |prov_name, info|
            if info.has_key?(:packages)
              info[:packages].each do |sub_name, sub_reference|
                unless init_package.call(sub_name, sub_reference)
                  package_success = false
                  break
                end
              end
            end
          end
        end
      end
      package_success
    end
    
    local_build_directory = File.join(build_directory, locations[:build])   
    
    FileUtils.mkdir_p(local_build_directory)
    
    # Build packages
    packages.each do |name, reference|
      unless init_package.call(name, reference)
        success = false
        break
      end
    end
    
    if success
      # Build provider specific components 
      success = yield(locations, package_info) if block_given?
    
      if success
        # Save the updates in the local project cache
        set_cache_setting(:build_locations, locations.export)
        set_cache_setting(:build_info, package_info.get([ :provisioners, plugin_provider ]))
        set_cache_setting(:build_profiles, find_profiles)
      end
    end
    success
  end
  
  #---
  
  def lookup(property, default = nil, options = {})
    # Implement in providers
    nil
  end
   
  #---
  
  def provision(profiles, options = {})
    config  = Config.ensure(options)
    success = yield(config) if block_given?
    
    Config.save_properties(Config.get_options(:corl_log)) if success
    success
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
      components = [ components.to_s.split('__') ].flatten
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

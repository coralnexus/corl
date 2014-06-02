
module CORL
module Plugin
class Provisioner < CORL.plugin_class(:nucleon, :base)
  
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
  
  def gateway(index = :first, reset = false)
    gateway = myself[:gateway]
    
    unless gateway
      gateways = package_gateways(reset)
      
      unless gateways.empty?
        if index == :first || index == 0
          gateway  = gateways[0]
        elsif index == :last
          gateway = gateways.pop
        elsif index.integer?
          gateway  = gateways[index]      
        end
      end
    end    
    gateway
  end
  
  def package_gateways(reset = false)
    gateways = []
    build_info(reset).each do |package_name, package_info|
      gateways << package_info[:gateway] if package_info.has_key?(:gateway)
    end
    gateways
  end
  
  #---
  
  def packages(environment = nil)
    process_environment(myself[:packages], environment)
  end
  
  #---
  
  def find_profiles(reset = false)
    allowed_profiles = []  
    build_info(reset).each do |package_name, package_info|
      hash(package_info[:profiles]).each do |profile_name, profile_info|
        allowed_profiles << concatenate([ package_name, 'profile', profile_name ])
      end
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
  
  def profile_dependencies(profiles)
    dependencies  = build_dependencies[:profile]    
    profile_index = {}
    
    search_profiles = lambda do |profile|
      profile = profile.to_sym
            
      if dependencies.has_key?(profile)
        dependencies[profile].each do |parent_profile|
          search_profiles.call(parent_profile)
        end
      end
      profile_index[profile] = true
    end
    
    profiles.each do |profile|
      search_profiles.call(profile)
    end
    
    profile_index.keys
  end
    
  #---
  
  def build_dependencies(reset = false)
    dependencies = cache_setting(:build_dependencies, {}, :hash)
    build if reset || dependencies.empty?
    symbol_map(cache_setting(:build_dependencies, {}, :hash))
  end
     
  #---
  
  def build_locations(reset = false)
    locations = cache_setting(:build_locations, {}, :hash)
    build if reset || locations.empty?
    symbol_map(cache_setting(:build_locations, {}, :hash))
  end
  
  #---
  
  def build_info(reset = false)
    info = cache_setting(:build_info, {}, :hash)
    build if reset || info.empty?
    symbol_map(cache_setting(:build_info, {}, :hash))
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
    config        = Config.ensure(options)
    success       = true    
    locations     = Config.new({ :build => id.to_s, :package => {} })
    dependencies  = Config.new
    package_info  = Config.new    
    package_names = {}
    
    node          = config[:node]
    environment   = Util::Data.ensure_value(config[:environment], node.lookup(:corl_environment))
    
    init_package = lambda do |name, reference|
      package_directory = File.join(locations[:build], 'packages', id(name).to_s)
      package_success   = true
      
      ui.info("Building package #{blue(name)} at #{purple(reference)} into #{green(package_directory)}")
      
      full_package_directory = File.join(build_directory, package_directory)
      
      unless package_names.has_key?(name)  
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
                process_environment(info[:packages], environment).each do |sub_name, sub_reference|
                  unless init_package.call(sub_name, sub_reference)
                    package_success = false
                  end
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
    packages(environment).each do |name, reference|
      unless init_package.call(name, reference)
        success = false
      end
    end
    
    if success
      # Build provider specific components
      success = yield(dependencies, locations, package_info, environment) if block_given?
    
      if success
        # Save the updates in the local project cache
        set_cache_setting(:build_dependencies, dependencies.export)
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
    config   = Config.ensure(options)    
    profiles = profile_dependencies(profiles)
    
    success = yield(profiles, config) if block_given?
    
    Config.save_properties(Config.get_options(:corl_log)) if success
    success
  end
       
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.build_info(namespace, plugin_type, data)  
    data = data.split(/\s*,\s*/) if data.is_a?(String)
    super(namespace, plugin_type, data)
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
  
  #---
  
  def process_environment(settings, environment = nil)
    config      = Config.new(hash(settings))
    env_config  = config.delete(:environment)
    environment = environment.to_sym if environment
    
    if env_config    
      if environment && env_config.has_key?(environment)
        local_env_config = env_config[environment]
        
        while local_env_config && local_env_config.has_key?(:use) do
          local_env_config = env_config[local_env_config[:use].to_sym]
        end
         
        config.defaults(local_env_config) if local_env_config
      end
      config.defaults(env_config[:default]) if env_config.has_key?(:default)
    end
    config.export  
  end
end
end
end

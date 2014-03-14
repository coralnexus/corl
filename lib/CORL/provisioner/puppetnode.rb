
module CORL
module Provisioner
class Puppetnode < CORL.plugin_class(:provisioner)
  
  @@puppet_lock = Mutex.new
  
  #-----------------------------------------------------------------------------
  # Provisioner plugin interface
   
  def normalize(reload)
    super do
      if CORL.log_level == :debug
        Puppet.debug = true
      end   
    end
  end
  
  #---
  
  def register
    env.modules.each do |mod|
      lib_dir = File.join(mod.path, 'lib')
      if File.directory?(lib_dir)
        logger.debug("Registering Puppet module at #{lib_dir}")
        CORL.register(lib_dir)
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
  
  def compiler
    @compiler
  end
   
  #---
  
  def env
    compiler.environment
  end
  
  #---
  
  def scope
    compiler.topscope
  end
  
  #---
  
  def catalog
    compiler.catalog
  end
  
  #-----------------------------------------------------------------------------
  # Resources
  
  def resource_types
    env.known_resource_types
  end
  
  #---
           
  def type_info(type_name, reset = false)
    type_name = type_name.to_s.downcase
    type_info = get(:type_info, {})
    
    if reset || ! type_info.has_key?(type_name)    
      resource_type = nil       
      type_exported, type_virtual = false
        
      if type_name.start_with?('@@')
        type_name     = type_name[2..-1]
        type_exported = true
          
      elsif type_name.start_with?('@')
        type_name    = type_name[1..-1]
        type_virtual = true
      end
        
      if type_name == 'class'
        resource_type = :class
      else
        if resource = Puppet::Type.type(type_name.to_sym)
          resource_type = :type
            
        elsif resource = find_definition(type_name)
          resource_type = :define
        end
      end
    
      type_info[type_name] = {
        :name     => type_name, 
        :type     => resource_type, 
        :resource => resource, 
        :exported => type_exported, 
        :virtual  => type_virtual 
      }
      set(:type_info, type_info)
    end
    
    type_info[type_name]  
  end
  
  #---
  
  def find_hostclass(name, options = {})
    resource_types.find_hostclass(scope.namespaces, name, options)
  end
  
  #---

  def find_definition(name)
    resource_types.find_definition(scope.namespaces, name)
  end
     
  #-----------------------------------------------------------------------------
  # Catalog alterations
      
  def add(type_name, resources, defaults = {}, options = {})
    info = type_info(type_name)
    PuppetExt::ResourceGroup.new(myself, info, defaults).add(resources, options)
  end
  
  #---
  
  def add_resource(type, title, properties)
    if type_name.is_a?(String)
      type = type_info(type)
    end
    
    case type[:type]
    when :type, :define
      add_definition(type, title, properties)
    when :class
      add_class(title, properties)
    end
  end

  #---
  
  def add_class(title, properties)
    klass = find_hostclass(title)
    if klass
      klass.ensure_in_catalog(scope, properties)
      catalog.add_class(title)
    end  
  end
  protected :add_class
    
  #---
  
  def add_definition(type, title, properties)    
    if type_name.is_a?(String)
      type = type_info(type)
    end
    
    resource          = Puppet::Parser::Resource.new(type[:name], title, :scope => scope, :source => type[:resource])
    resource.virtual  = type[:virtual]
    resource.exported = type[:exported]
    
    namevar       = namevar(type[:name], title).to_sym
    resource_name = properties.has_key?(namevar) ? properties[namevar] : title
    
    { :name => resource_name }.merge(properties).each do |key, value|
      resource.set_parameter(key, value)
    end
    if type[:type] == :define
      type[:resource].instantiate_resource(scope, resource)
    end
    compiler.add_resource(scope, resource)
  end
  protected :add_definition

  #-----------------------------------------------------------------------------
  # Puppet operations
  
  def build(options = {})
    super do |locations, package_info, init_location|
      init_location.call(:modules, nil)
      
      init_location.call(:profiles, :pp)
      init_location.call(:default, :pp)
        
      # Build modules
      
      locations[:module] = {}
      
      init_profile = lambda do |package_name, profile_name, profile_info|
        package_id     = id(package_name)
        base_directory = File.join(locations[:modules], package_id.to_s, profile_name.to_s)
        
        if profile_info.has_key?(:modules)
          profile_info[:modules].each do |module_name, module_reference|
            module_directory = File.join(base_directory, module_name.to_s)
                
            module_project = CORL.project(extended_config(:puppet_module, {
              :directory => File.join(build_directory, module_directory),
              :url       => module_reference,
              :create    => true,
              :pull      => true
            }))
            raise unless module_project                
          end
          locations[:module][profile_id(package_name, profile_name)] = base_directory
        end
      end     
      
      hash(package_info.get([ :provisioners, plugin_provider ])).each do |package_name, info|
        if info.has_key?(:profiles)
          info[:profiles].each do |profile_name, profile_info|
            init_profile.call(package_name, profile_name, profile_info)
          end
        end
      end
      profiles.each do |profile_name, profile_info|
        init_profile.call(plugin_name, profile_name, profile_info)
      end
    end     
  end
  
  #---
  
  def lookup(property, default = nil, options = {})
    config = Config.ensure(options)
    value  = nil
    
    puppet_scope   = config.get(:puppet_scope, scope)    
    base_names     = config.get(:search, nil)     
    search_name    = config.get(:search_name, true)
    reverse_lookup = config.get(:reverse_lookup, true)
    
    log_level = ::Puppet::Util::Log.level
    Puppet::Util::Log.level = :err # Don't want failed parameter lookup warnings here.
      
    if base_names
      if base_names.is_a?(String)
        base_names = [ base_names ]
      end
      base_names = base_names.reverse if reverse_lookup
        
      base_names.each do |base|
        value = puppet_scope.lookupvar("::#{base}::#{property}")
        break unless Util::Data.undef?(value)  
      end
    end
    if Util::Data.undef?(value)
      components = property.split('::')
      
      if components.length > 1
        #last = components.pop
        components += [ 'default', components.pop ]
        value = puppet_scope.lookupvar('::' + components.flatten.join('::'))
      end
    end
    if Util::Data.undef?(value) && search_name
      value = puppet_scope.lookupvar("::#{property}")
    end
    
    Puppet::Util::Log.level = log_level
    value      
  end
  
  #--
  
  def import(files)
    array(files).each do |file|
      resource_types.loader.import(file, network.directory)
    end
  end
  
  #---
  
  def include(resource_name, properties = {})
    class_data = {}
    
    if resource_name.is_a?(Array)
      resource_name = resource_name.flatten
    else
      resource_name = [ resource_name ]
    end
     
    resource_name.each do |name|
      class_data[name.to_s] = properties  
    end
    
    klasses = compiler.evaluate_classes(class_data, scope, false)
    missing = class_data.keys.find_all do |klass|
      ! klasses.include?(klass)
    end
    return false unless missing.empty?
    true
  end
  
  #---
  
  def add_search_path(type, resource_name)
    Config.set_options([ :all, type ], { :search => [ resource_name.to_s ] })  
  end
   
  #---
    
  def provision(profiles, options = {})
    locations = build_locations
    
    include_location = lambda do |type, add_to_catalog = true, add_search_path = false|      
      locations[:package].each do |name, package_directory|
        gateway       = File.join(build_directory, package_directory, "#{type}.pp")
        resource_name = concatenate([ name, type ])
        
        add_search_path(type, resource_name) if add_search_path
        
        if File.exists?(gateway)
          import(gateway)
          include(resource_name, { :before => 'Anchor[gateway-init]' }) if add_to_catalog                   
        end
        
        directory = File.join(build_directory, package_directory, type.to_s)
        Dir.glob(File.join(directory, '*.pp')).each do |file|
          resource_name = concatenate([ name, type, File.basename(file).gsub('.pp', '') ])
          import(file)
          include(resource_name, { :before => 'Anchor[gateway-init]' }) if add_to_catalog
        end        
      end
    
      gateway       = File.join(build_directory, locations[:build], "#{type}.pp")
      resource_name = concatenate([ plugin_name, type ])
      
      add_search_path(type, resource_name) if add_search_path
     
      if File.exists?(gateway)
        import(gateway)
        include(resource_name, { :before => 'Anchor[gateway-init]' }) if add_to_catalog                   
      end
    
      if locations.has_key?(type)
        directory = File.join(build_directory, locations[type])
        Dir.glob(File.join(directory, '*.pp')).each do |file|
          resource_name = concatenate([ plugin_name, type, File.basename(file).gsub('.pp', '') ])
          import(file)
          include(resource_name, { :before => 'Anchor[gateway-init]' }) if add_to_catalog
        end
      end
    end
    
    @@puppet_lock.synchronize do
      init_puppet(profiles)
      register     
      
      # Include defaults
      include_location.call(:default, true, true)
      
      env.modules.each do |mod|
        default_file = File.join(mod.path, 'manifests', 'default.pp')
        
        if File.exists?(default_file)
          import(default_file)
          include("#{mod.name}::default", { :before => 'Anchor[gateway-init]' })
        end  
      end
      
      # Import and include needed profiles
      include_location.call(:profiles, false)
      
      profiles.each do |profile|
        include(profile, { :require => 'Anchor[gateway-exit]' })
      end
      
      begin
        dbg(catalog, 'puppet catalog')
      
        #configurer = Puppet::Configurer.new
        #configurer.run(:catalog => catalog, :pluginsync => false)
      
      rescue Exception => error
        raise error
        Puppet.log_exception(error)
      end
    end    
    false
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def init_puppet(profiles)
    locations = build_locations
    
    # Must be in this order!!
    Puppet.initialize_settings
    
    # TODO: Figure out how to store these damn settings in a specialized
    # environment without phantom empty environment issues.
      
    node = get_node    
    Puppet[:node_name_value] = id
    
    if manifest = gateway
      if manifest.match(/^packages\/.*/)
        manifest = File.join(build_directory, locations[:build], manifest)
      else
        manifest = File.join(network.directory, directory, manifest)    
      end    
      Puppet[:manifest] = manifest   
    end
    
    unless profiles.empty?
      modulepath = profiles.collect do |profile|
        File.join(build_directory, locations[:module][profile.to_sym])
      end
      Puppet[:modulepath] = array(modulepath).join(File::PATH_SEPARATOR)
    end
    
    @compiler = Puppet::Parser::Compiler.new(node)
            
    # Initialize the compiler so we can can lookup and include stuff
    # This is ugly but seems to be the only way.
    compiler.compile   
  end
  protected :init_puppet
  
  #---
   
  def get_node
    node = Puppet::Node.indirection.find(id)
         
    if facts = Puppet::Node::Facts.indirection.find(id)
      facts.name = id
      node.merge(facts.values)
    end
    node
  end
  protected :get_node
  
  #---
 
  def profile_id(package_name, profile_name)
    concatenate([ package_name, 'profile', profile_name ], false)
  end
  
  #---
  
  def to_name(name)
    Util::Data.value(name).to_s.gsub(/[\/\\\-\.]/, '_')
  end
  
  #---
  
  def type_name(value) # Basically borrowed from Puppet (damn private methods!)
    return :main if value == :main
    return "Class" if value == "" or value.nil? or value.to_s.downcase == "component"
    value.to_s.split("::").collect { |s| s.capitalize }.join("::")
  end
  
  #---
  
  def namevar(type_name, resource_name) # Basically borrowed from Puppet (damn private methods!)
    resource = Puppet::Resource.new(type_name.sub(/^\@?\@/, ''), resource_name)
    
    if resource.builtin_type? and type = resource.resource_type and type.key_attributes.length == 1
      type.key_attributes.first.to_s
    else
      'name'
    end
  end
  
  #---
  
  def concatenate(components, capitalize = false)
    super(components, capitalize, '::')
  end
end
end
end

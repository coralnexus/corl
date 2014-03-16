
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
  
  def register(options = {})
    Util::Puppet.register_plugins(Config.ensure(options).defaults({ :puppet_scope => scope }))
  end
  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
  
  def compiler
    @compiler
  end
  
  #---
  
  def scope
    return compiler.topscope if compiler
    nil
  end
  
  #-----------------------------------------------------------------------------
  # Puppet initialization
    
  def init_puppet(profiles)
    locations = build_locations
    
    # Must be in this order!!
    Puppet.initialize_settings
    Puppet::Util::Log.newdestination(:console)
    
    # TODO: Figure out how to store these damn settings in a specialized
    # environment without phantom empty environment issues.
      
    node = get_node    
    Puppet[:node_name_value] = id.to_s
    
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
    register
     
    # Initialize the compiler so we can can lookup and include stuff
    # This is ugly but seems to be the only way.
    compiler.compile
  end
  protected :init_puppet
  
  #---
   
  def get_node
    node_id = id.to_s
    node    = Puppet::Node.indirection.find(node_id)
         
    if facts = Puppet::Node::Facts.indirection.find(node_id)
      facts.name = node_id
      node.merge(facts.values)
    end
    node
  end
  protected :get_node
  
  #-----------------------------------------------------------------------------
  # Provisioner interface operations
  
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
    Util::Puppet.lookup(property, default, Config.ensure(options).defaults({ 
      :provisioner  => :puppetnode,
      :puppet_scope => scope      
    }))
  end
  
  #--
  
  def import(files, options = {})
    Util::Puppet.import(files, Config.ensure(options).defaults({ 
      :puppet_scope       => scope, 
      :puppet_import_base => network.directory 
    }))
  end
  
  #---
  
  def include(resource_name, properties = {}, options = {})
    Util::Puppet.include(resource_name, properties, Config.ensure(options).defaults({
      :provisioner  => :puppetnode, 
      :puppet_scope => scope      
    }))
  end
  
  #---
  
  def add_search_path(type, resource_name)
    Config.set_options([ :all, type ], { :search => [ resource_name.to_s ] })  
  end
   
  #---
    
  def provision(profiles, options = {})
    locations = build_locations
    success   = true
    
    include_location = lambda do |type, add_to_catalog = true, add_search_path = false|      
      locations[:package].each do |name, package_directory|
        gateway       = File.join(build_directory, package_directory, "#{type}.pp")
        resource_name = concatenate([ name, type ])
        
        add_search_path(type, resource_name) if add_search_path
        
        if File.exists?(gateway)
          import(gateway)
          include(resource_name, { :before => 'Anchor[gateway_init]' }) if add_to_catalog                   
        end
        
        directory = File.join(build_directory, package_directory, type.to_s)
        Dir.glob(File.join(directory, '*.pp')).each do |file|
          resource_name = concatenate([ name, type, File.basename(file).gsub('.pp', '') ])
          import(file)
          include(resource_name, { :before => 'Anchor[gateway_init]' }) if add_to_catalog
        end        
      end
    
      gateway       = File.join(build_directory, locations[:build], "#{type}.pp")
      resource_name = concatenate([ plugin_name, type ])
      
      add_search_path(type, resource_name) if add_search_path
     
      if File.exists?(gateway)
        import(gateway)
        include(resource_name, { :before => 'Anchor[gateway_init]' }) if add_to_catalog                   
      end
    
      if locations.has_key?(type)
        directory = File.join(build_directory, locations[type])
        Dir.glob(File.join(directory, '*.pp')).each do |file|
          resource_name = concatenate([ plugin_name, type, File.basename(file).gsub('.pp', '') ])
          import(file)
          include(resource_name, { :before => 'Anchor[gateway_init]' }) if add_to_catalog
        end
      end
    end
    
    @@puppet_lock.synchronize do
      begin
        start_time = Time.now
        
        init_puppet(profiles)
        
        # Include defaults
        include_location.call(:default, true, true)
      
        # Import and include needed profiles
        include_location.call(:profiles, false)
      
        profiles.each do |profile|
          include(profile, { :require => 'Anchor[gateway_exit]' })
        end
        
        # Start system configuration 
        catalog = compiler.catalog.to_ral
        catalog.finalize
        catalog.retrieval_duration = Time.now - start_time
        
        configurer = Puppet::Configurer.new
        if ! configurer.run(:catalog => catalog, :pluginsync => false)
          success = false
        end
      
      rescue Exception => error
        raise error
        Puppet.log_exception(error)
      end
    end    
    success
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def profile_id(package_name, profile_name)
    concatenate([ package_name, 'profile', profile_name ], false)
  end
   
  #---
  
  def concatenate(components, capitalize = false)
    super(components, capitalize, '::')
  end
end
end
end

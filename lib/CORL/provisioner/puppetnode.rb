module CORL
module Provisioner
class Puppetnode < CORL.plugin_class(:provisioner)
  
  @@puppet_lock = Mutex.new
  
  #---
  
  @@status = {}
  
  def self.status
    @@status
  end
  
  #-----------------------------------------------------------------------------
  # Provisioner plugin interface
   
  def normalize(reload)
    super do
      if CORL.log_level == :debug
        Puppet.debug = true
      end
      unless reload
        Puppet::Util::Log.newdesttype id do
          def handle(msg)
            levels = {
              :emerg => { :name => 'emergency', :send => :error },
              :alert => { :name => 'alert', :send => :error },
              :crit => { :name => 'critical', :send => :error },
              :err => { :name => 'error', :send => :error },
              :warning => { :name => 'warning', :send => :warn },
              :notice => { :name => 'notice', :send => :success },
              :info => { :name => 'info', :send => :info },
              :debug => { :name => 'debug', :send => :info }
            }
            str = msg.respond_to?(:multiline) ? msg.multiline : msg.to_s
            str = msg.source == "Puppet" ? str : "#{CORL.blue(msg.source)}: #{str}"
            level = levels[msg.level]
            
            if [ :warn, :error ].include?(level[:send])
              ::CORL::Provisioner::Puppetnode.status[name] = 111
            end
        
            CORL.ui_group("puppetnode::#{name}(#{CORL.yellow(level[:name])})", :cyan) do |ui|
              ui.send(level[:send], str)
            end
          end
        end
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
    
    Puppet.initialize_settings
    Puppet::Util::Log.newdestination(id)
    
    # TODO: Figure out how to store these damn settings in a specialized
    # environment without phantom empty environment issues.
    
    Puppet[:graph] = true if CORL.log_level == :error
    
    Puppet[:data_binding_terminus] = 'corl'
    Puppet[:default_file_terminus] = :file_server
    Puppet[:node_name_value]       = id.to_s
    
    unless profiles.empty?
      modulepath = []
      profiles.each do |profile|
        profile_dir = File.join(build_directory, locations[:module][profile.to_sym])
        modulepath << profile_dir if File.directory?(profile_dir)
      end
      Puppet[:modulepath] = array(modulepath).join(File::PATH_SEPARATOR)
    end
    
    if manifest = gateway
      if manifest.match(/^packages\/.*/)
        manifest = File.join(build_directory, locations[:build], manifest)
      else
        manifest = File.join(network.directory, directory, manifest)
      end
      Puppet[:manifest] = manifest
    end
    
    node      = get_node
    @compiler = Puppet::Parser::Compiler.new(node)
    register
    node
  end
  protected :init_puppet
  
  #---
   
  def get_node
    node_id = id.to_s
    node = Puppet::Node.indirection.find(node_id)
         
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
    super do |dependencies, locations, package_info, environment|
      success = true
      
      # Build modules
      locations[:module]     = {}
      dependencies[:profile] = {}
      
      init_profile = lambda do |package_name, profile_name, profile_info, profiles = nil|
        package_id = id(package_name)
        base_directory = File.join(locations[:build], 'modules', package_id.to_s, profile_name.to_s)
        profile_success = true
        
        ui.info("Building CORL profile #{blue(profile_name)} modules into #{green(base_directory)}")
        
        profile_parents = []
        profile_config  = Config.new(profile_info)
            
        while profile_config.has_key?(:extend) do
          array(profile_config.delete(:extend)).each do |parent_profile|
            profile_parents << profile_id(package_name, parent_profile)
            profile_config.defaults(profiles[parent_profile.to_sym])
          end
        end
        
        profile_info = process_environment(profile_info, environment)
        
        dependencies[:profile][profile_id(package_name, profile_name)] = profile_parents
                
        if profile_info.has_key?(:modules)
          profile_info[:modules].each do |module_name, module_reference|
            module_directory = File.join(base_directory, module_name.to_s)
            
            ui.info("Building Puppet module #{blue(module_name)} at #{purple(module_reference)} into #{green(module_directory)}")
            
            full_module_directory = File.join(build_directory, module_directory)
                
            module_project = CORL.project(extended_config(:puppet_module, {
              :directory => full_module_directory,
              :url => module_reference,
              :create => File.directory?(full_module_directory) ? false : true,
              :pull => true
            }))
            unless module_project
              ui.warn("Puppet module #{cyan(module_name)} failed to initialize")
              profile_success = false
            end
          end
          locations[:module][profile_id(package_name, profile_name)] = base_directory if profile_success
        end
        profile_success
      end
      
      hash(package_info.get([ :provisioners, plugin_provider ])).each do |package_name, info|
        if info.has_key?(:profiles)
          info[:profiles].each do |profile_name, profile_info|
            unless init_profile.call(package_name, profile_name, profile_info, info[:profiles])
              success = false
            end
          end
        end
      end
      success
    end
  end
  
  #---
  
  def lookup(property, default = nil, options = {})
    Util::Puppet.lookup(property, default, Config.ensure(options).defaults({
      :provisioner => :puppetnode,
      :puppet_scope => scope
    }))
  end
  
  #--
  
  def import(files, options = {})
    Util::Puppet.import(files, Config.ensure(options).defaults({
      :puppet_scope => scope,
      :puppet_import_base => network.directory
    }))
  end
  
  #---
  
  def add_search_path(type, resource_name)
    Config.set_options([ :all, type ], { :search => [ resource_name.to_s ] })
  end
   
  #---
    
  def provision(profiles, options = {})
    super do |processed_profiles, config|
      locations = build_locations
      success = true
    
      include_location = lambda do |type, parameters = {}, add_search_path = false|
        classes = {}
            
        locations[:package].each do |name, package_directory|
          type_gateway = File.join(build_directory, package_directory, "#{type}.pp")
          resource_name = concatenate([ name, type ])
        
          add_search_path(type, resource_name) if add_search_path
        
          if File.exists?(type_gateway)
            import(type_gateway)
            classes[resource_name] = parameters
          end
        
          type_directory = File.join(build_directory, package_directory, type.to_s)
          Dir.glob(File.join(type_directory, '*.pp')).each do |file|
            resource_name = concatenate([ name, type, File.basename(file).gsub('.pp', '') ])
            import(file)
            classes[resource_name] = parameters
          end
        end
    
        type_gateway = File.join(directory, "#{type}.pp")
        resource_name = concatenate([ plugin_name, type ])
      
        add_search_path(type, resource_name) if add_search_path
     
        if File.exists?(type_gateway)
          import(type_gateway)
          classes[resource_name] = parameters
        end
    
        type_directory = File.join(directory, type.to_s)
        
        if File.directory?(type_directory)
          Dir.glob(File.join(type_directory, '*.pp')).each do |file|
            resource_name = concatenate([ plugin_name, type, File.basename(file).gsub('.pp', '') ])
            import(file)
            classes[resource_name] = parameters
          end
        end
        classes
      end
    
      @@puppet_lock.synchronize do
        begin
          ui.info("Starting catalog generation")
          
          @@status[id] = code.success
          
          start_time = Time.now
          node = init_puppet(processed_profiles)
        
          # Include defaults
          classes = include_location.call(:default, {}, true)
      
          # Import needed profiles
          include_location.call(:profiles, {}, false)
      
          processed_profiles.each do |profile|
            classes[profile.to_s] = { :require => 'Anchor[profile_start]' }
          end
          
          # Compile catalog
          node.classes = classes
          compiler.compile
        
          # Start system configuration
          catalog = compiler.catalog.to_ral
          catalog.finalize
          catalog.retrieval_duration = Time.now - start_time
          
          unless config.get(:dry_run, false)
            ui.info("\n", { :prefix => false })
            ui.info("Starting configuration run")
                        
            configurer = Puppet::Configurer.new
            if ! configurer.run(:catalog => catalog, :pluginsync => false)
              success = false
            end
          end
        
        rescue Exception => error
          raise error
          Puppet.log_exception(error)
        end
      end
      success = false if @@status[id] != code.success
      success
    end
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

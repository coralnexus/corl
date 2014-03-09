
module CORL
module Provisioner
class Puppetnode < CORL.plugin_class(:provisioner)
  
  #-----------------------------------------------------------------------------
  # Provisioner plugin interface
   
  def normalize(reload)
    super do
      unless reload
        if CORL.log_level == :debug
          Puppet.debug = true
        end
        Puppet.initialize_settings
                
        @env      = Puppet::Node::Environment.new(id)
        @compiler = Puppet::Parser::Compiler.new(node)
      end    
      init_scope
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
  
  def set_puppet_setting(name, value)
    Puppet.settings.set_value(name.to_sym, value, id)
  end
  
  #---
  
  def modulepath=modulepath
    set_puppet_setting(:modulepath, array(modulepath))
    register
  end
  
  #---

  def modules=modules
    myself[:modules] = hash(modules)
  end
  
  def modules
    hash(myself[:modules])
  end
   
  def env
    @env
  end
  
  #---
  
  def compiler
    @compiler
  end
  
  #---
    
  def init_facts
    facts = {}
    
    unless Puppet[:node_name_value].empty?
      facts_obj = Puppet::Node::Facts.indirection.find(Puppet[:node_name_value])
      facts     = facts_obj.values if facts_obj
    end
    
    @facts = facts  
  end
  protected :init_facts
  
  #---
  
  def facts(reset = false)
    if reset || ! @facts
      init_facts
    end
    @facts
  end
  
  #---
  
  def init_node
    if name
      name_orig = Puppet[:node_name_value]
      Puppet[:node_name_value] = name
    end
    
    node = Puppet::Node.indirection.find(Puppet[:node_name_value])
    
    if facts = facts(true)
      node.merge(facts.values)
    end

    file = Puppet[:classfile]
    if FileTest.exists?(file)
      node.classes = File.read(file).split(/[\s\n]+/)
    end
    
    Puppet[:node_name_value] = name_orig if name_orig
    @node = node
  end
  protected :init_node
  
  #---
  
  def node(reset = false)
    if reset || ! @node
      init_node
    end
    @node
  end
  
  #---
  
  def init_scope
    @scope       = Puppet::Parser::Scope.new(compiler)
    scope.source = Puppet::Resource::Type.new(:node, node.name)
    scope.parent = compiler.topscope  
  end

  #---
  
  def scope
    @scope
  end
  
  #---
  
  def init_catalog
    node = node(true)
    
    starttime = Time.now
    catalog   = Puppet::Resource::Catalog.indirection.find(node.name, :use_node => node)

    catalog = catalog.to_ral
    catalog.finalize

    catalog.retrieval_duration = Time.now - starttime

    catalog.write_class_file
    catalog.write_resource_file
    
    @catalog = catalog  
  end
  
  #---
  
  def catalog(reset = false)
    if reset || ! @catalog
      init_catalog
    end
    @catalog
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
  
  def clear
    init_catalog
    myself
  end
  
  #---
      
  def add(type_name, resources, defaults = {}, options = {})
    info = type_info(type_name)
    PuppetExt::ResourceGroup.new(self, info, defaults).add(resources, options)
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
  
  def build(build_directory)
    super do |locations, init_location|
      init_location.call(:modules, nil)
      
      init_location.call(:profiles, :pp)
      init_location.call(:default, :pp)
      
      # Build modules
      
      
    end  
  end
  
  #---
  
  def lookup(property, default = nil, options = {})
    config = Config.ensure(options)
    value  = nil
    
    puppet_scope = config.get(:puppet_scope, scope)
    
    base_names = config.get(:search, nil)
     
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
    if Util::Data.undef?(value) && search_name
      value = puppet_scope.lookupvar("::#{property}")
    end
    
    Puppet::Util::Log.level = log_level
    value      
  end
  
  #--
  
  def import(files, base_dir = nil)
    resource_types.loader.import(file, base_dir + '/')
  end
  
  #---
  
  def include(resource_name, properties, options = {})
    class_data = {}
    
    if resource_name.is_a?(Array)
      resource_name = resource_name.flatten
    else
      resource_name = [ resource_name ]
    end
      
    resource_name.each do |name|
      classes = lookup(name, [], options)
      if classes.is_a?(Array)
        classes.each do |klass|
          class_data[klass] = parameters
        end
      end  
    end
      
    klasses = compiler.evaluate_classes(class_data, myself, false)
    missing = class_data.keys.find_all do |klass|
      ! klasses.include?(klass)
    end

    return false unless missing.empty?
    true
  end
  
  #---
    
  def provision(options = {})
    config = Config.ensure(options)
    
    if ! Util::Data.empty?(config[:code])
      Puppet[:code] = config[:code]
      
    elsif ! Util::Data.empty?(config[:manifest])
      Puppet[:manifest] = config[:manifest]
    end

    begin
      return configure(config[:node])
      
    rescue => detail
      Puppet.log_exception(detail)
    end
    false
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
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
  
  def configure
    configurer = Puppet::Configurer.new
    configurer.run(:catalog => catalog, :pluginsync => false)
  end
  protected :configure
end
end
end

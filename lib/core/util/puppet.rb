
module CORL
module Util
module Puppet
  
  def self.logger
    CORL.logger
  end
  
  #-----------------------------------------------------------------------------
  # Plugins
  
  @@register = {}
  
  #---
  
  def self.register_plugins(options = {})
    config = Config.ensure(options)
    
    puppet_scope = config.get(:puppet_scope, nil)
    return unless puppet_scope
    
    each_module(config) do |mod|
      unless @@register.has_key?(mod.path)
        lib_dir = File.join(mod.path, 'lib')
        if File.directory?(lib_dir)
          logger.debug("Registering Puppet module at #{lib_dir}")
          CORL.register(lib_dir)
          @@register[mod.path] = true
        end
      end
    end
  end
    
  #-----------------------------------------------------------------------------
  # Resources
           
  def self.type_info(type_name, options = {})
    config = Config.ensure(options)
    reset  = config.get(:reset, false)
    
    puppet_scope = config.get(:puppet_scope, nil)
    return nil unless puppet_scope
    
    type_name = type_name.to_s.downcase
    type_info = config.get(:type_info, {})
    
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
        if resource = ::Puppet::Type.type(type_name.to_sym)
          resource_type = :type
            
        elsif resource = puppet_scope.find_definition(type_name)
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
      config.set(:type_info, type_info)
    end
    
    type_info[type_name]  
  end
  
  #-----------------------------------------------------------------------------
  # Catalog alterations
      
  def self.add(type_name, resources, defaults = {}, options = {})
    config  = Config.ensure(options)
    
    puppet_scope = config.get(:puppet_scope, nil)    
    return unless puppet_scope
    
    info = type_info(type_name, options)
    ResourceGroup.new(info, defaults).add(resources, config)
  end
  
  #---
  
  def self.add_resource(type, title, properties, options = {})
    config  = Config.ensure(options)
    
    puppet_scope = config.get(:puppet_scope, nil)    
    return unless puppet_scope
    
    if type.is_a?(String)
      type = type_info(type, config)
    end
    
    case type[:type]
    when :type, :define
      CORL.ui_group(puppet_scope.source.module_name) do |ui|
        #ui.info("Adding #{type[:name]} #{title} definition")
      end
      add_definition(type, title, properties, config)
    when :class
      CORL.ui_group(puppet_scope.source.module_name) do |ui|
        #ui.info("Adding #{title} class")
      end
      add_class(title, properties, config)
    end
  end

  #---
  
  def self.add_class(title, properties, options = {})
    config       = Config.ensure(options)    
    puppet_scope = config.get(:puppet_scope, nil)
        
    if puppet_scope
      klass = puppet_scope.find_hostclass(title)
      return unless klass
      
      #dbg(properties, "class #{title}")
      klass.ensure_in_catalog(puppet_scope, properties)
      puppet_scope.catalog.add_class(title)
    end  
  end
    
  #---
  
  def self.add_definition(type, title, properties, options = {})
    config       = Config.ensure(options)
    
    puppet_scope = config.get(:puppet_scope, nil)    
    return unless puppet_scope
        
    type = type_info(type, config) if type.is_a?(String)
        
    resource          = ::Puppet::Parser::Resource.new(type[:name], title, :scope => puppet_scope, :source => type[:resource])
    resource.virtual  = type[:virtual]
    resource.exported = type[:exported]
    
    namevar       = namevar(type[:name], title).to_sym
    resource_name = properties.has_key?(namevar) ? properties[namevar] : title
    
    { :name => resource_name }.merge(properties).each do |key, value|
      resource.set_parameter(key, value)
    end
    if type[:type] == :define
      type[:resource].instantiate_resource(puppet_scope, resource)
    end
    #dbg(resource, "definition/type #{type[:type]} #{title}")
    puppet_scope.compiler.add_resource(puppet_scope, resource)
  end
    
  #--
  
  def self.import(files, options = {})
    config = Config.ensure(options)    
    
    puppet_scope = config.get(:puppet_scope, nil)  
    return unless puppet_scope
    
    if types = puppet_scope.environment.known_resource_types
      Util::Data.array(files).each do |file|
        types.loader.import(file, config.get(:puppet_import_base, nil))
      end
    end
  end
  
  #---
  
  def self.include(resource_name, properties = {}, options = {})
    config     = Config.ensure(options)
    class_data = {}
        
    puppet_scope = config.get(:puppet_scope, nil)
    return false unless puppet_scope
    
    if resource_name.is_a?(Array)
      resource_name = resource_name.flatten
    else
      resource_name = [ resource_name ]
    end
    
    resource_name.each do |name|
      classes = Config.lookup(name, nil, config)
      if classes.is_a?(Array)
        classes.each do |klass|
          class_data[klass] = properties
        end
      else
        class_data[name.to_s] = properties  
      end
    end
    
    klasses = puppet_scope.compiler.evaluate_classes(class_data, puppet_scope, false)
    missing = class_data.keys.find_all do |klass|
      ! klasses.include?(klass)
    end
    return false unless missing.empty?
    true
  end
    
  #-----------------------------------------------------------------------------
  # Lookup
  
  def self.lookup(property, default = nil, options = {})
    config = Config.ensure(options)
    value  = nil
    
    puppet_scope   = config.get(:puppet_scope, nil)    
    base_names     = config.get(:search, nil)     
    search_name    = config.get(:search_name, true)
    reverse_lookup = config.get(:reverse_lookup, true)
    
    return default unless puppet_scope
    
    log_level = ::Puppet::Util::Log.level
    ::Puppet::Util::Log.level = :err # Don't want failed parameter lookup warnings here.
      
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
      components = property.to_s.split('::')
      
      if components.length > 1
        components += [ 'default', components.pop ]
        value = puppet_scope.lookupvar('::' + components.flatten.join('::'))
      end
    end
    if Util::Data.undef?(value) && search_name
      value = puppet_scope.lookupvar("::#{property}")
    end
    
    ::Puppet::Util::Log.level = log_level
    value      
  end
   
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.each_module(options = {}, &code)
    config = Config.ensure(options)
    values = []
    
    puppet_scope = config.get(:puppet_scope, nil)  
    return nil unless puppet_scope
    
    puppet_scope.compiler.environment.modules.each do |mod|
      values << code.call(mod)
    end
    values
  end
  
  #---
 
  def self.to_name(name)
    Util::Data.value(name).to_s.gsub(/[\/\\\-\.]/, '_')
  end
  
  #---
  
  def self.type_name(value)
    return :main if value == :main
    return "Class" if value == "" or value.nil? or value.to_s.downcase == "component"
    value.to_s.split("::").collect { |s| s.capitalize }.join("::")
  end
  
  #---
  
  def self.namevar(type_name, resource_name)
    resource = ::Puppet::Resource.new(type_name.sub(/^\@?\@/, ''), resource_name)
    
    if resource.builtin_type? and type = resource.resource_type and type.key_attributes.length == 1
      type.key_attributes.first.to_s
    else
      'name'
    end
  end      
end
end
end
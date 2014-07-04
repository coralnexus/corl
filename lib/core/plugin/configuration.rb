
module CORL
module Plugin
class Configuration < CORL.plugin_class(:nucleon, :base)
    
  include Mixin::SubConfig

  #---
  
  def self.register_ids
    [ :name, :directory ]
  end
   
  #-----------------------------------------------------------------------------
  # Configuration plugin interface
  
  def normalize(reload)
    super
    
    logger.debug("Initializing source sub configuration")
    init_subconfig(true) unless reload
    
    logger.info("Setting source configuration project")
    @project = CORL.project(extended_config(:project, {
      :directory     => _delete(:directory, Dir.pwd),
      :url           => _delete(:url),
      :revision      => _delete(:revision),
      :create        => _delete(:create, false),
      :pull          => true,
      :internal_ip   => CORL.public_ip, # Needed for seeding Vagrant VMs
      :manage_ignore => _delete(:manage_ignore, true)
    }), _delete(:project_provider))
        
    _init(:autoload, true)
    _init(:autosave, false)
    
    yield if block_given?
    
    set_location(@project)
  end
  
  #---
  
  def remove_plugin
    CORL.remove_plugin(@project)
  end
   
  #-----------------------------------------------------------------------------
  # Checks
  
  def can_persist?
    project.can_persist?
  end
      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers

  def project
    @project
  end
  
  #---
  
  def directory
    project.directory  
  end
  
  #---
  
  def cache
    project.cache
  end
  
  #---
  
  def ignore(files)
    project.ignore(files)
  end
  
  #---
  
  def autoload(default = false)
    _get(:autoload, default)
  end
  
  def autoload=autoload
    _set(:autoload, test(autoload))
  end
   
  #---
  
  def autosave(default = false)
    _get(:autosave, default)
  end
  
  def autosave=autosave
    _set(:autosave, test(autosave))
  end

  #-----------------------------------------------------------------------------
  
  def set_location(directory)
    if directory && directory.is_a?(CORL::Plugin::Project)
      logger.debug("Setting source project directory from other project at #{directory.directory}")
      project.set_location(directory.directory)
      
    elsif directory && directory.is_a?(String) || directory.is_a?(Symbol)
      logger.debug("Setting source project directory to #{directory}")
      project.set_location(directory.to_s)
    end
  end
  
  #-----------------------------------------------------------------------------
    
  def set(keys, value = '', options = {})
    super(keys, value)
    save(options) if initialized? && autosave
  end
   
  #---
   
  def delete(keys, options = {})
    super(keys)
    save(options) if initialized? && autosave
  end
  
  #---
  
  def clear(options = {})
    super
    save(options) if initialized? && autosave
  end
  
  #-----------------------------------------------------------------------------
  
  def remote(name)
    project.remote(name)
  end
  
  #---
  
  def set_remote(name, location)
    project.set_remote(name, location)
  end
 
  #-----------------------------------------------------------------------------
  # Import / Export
  
  def import(properties, options = {})
    super(properties, options)
    save(options) if autosave
  end
      
  #-----------------------------------------------------------------------------
  # Configuration loading / saving
    
  def load(options = {})
    method_config = Config.ensure(options)
    success = false
    
    if can_persist?
      if extension_check(:load, { :config => method_config })
        logger.info("Loading source configuration")
      
        config.clear if method_config.get(:override, false)
      
        properties = Config.new
        yield(method_config, properties) if block_given?
          
        unless properties.export.empty?
          logger.debug("Source configuration parsed properties: #{properties}")
        
          extension(:load_process, { :properties => properties, :config => method_config })               
          config.import(properties, method_config)
        end
        success = true
      end
    else
      logger.warn("Loading of source configuration failed")
    end
    success
  end
   
  #---
    
  def save(options = {})
    method_config = Config.ensure(options)
    success       = false
    
    if can_persist?
      if extension_check(:save, { :config => method_config })
        logger.info("Saving source configuration")
        logger.debug("Source configuration properties: #{config.export}") 
      
        success = yield(method_config) if block_given?
      end
    else
      logger.warn("Can not save source configuration")
    end
    success
  end
  
  #---
  
  def remove(options = {})
    method_config = Config.ensure(options)
    success       = false
    
    if can_persist?
      if extension_check(:delete, { :config => method_config })
        logger.info("Removing source configuration")
      
        config.clear
      
        success = yield(method_config) if block_given?
      end
    else
      logger.warn("Can not remove source configuration")
    end
    success
  end
  
  #---
  
  def attach(type, name, data, options = {})
    method_config = Config.ensure(options)
    new_location  = nil
    
    if can_persist?
      if extension_check(:attach, { :config => method_config })
        logger.info("Attaching data to source configuration")
      
        new_location = yield(method_config) if block_given?
      end
    else
      logger.warn("Can not attach data to source configuration")
    end
    new_location
  end
  
  #---
  
  def delete_attachments(type, ids, options = {})
    method_config = Config.ensure(options)
    locations     = []
    
    if can_persist?
      if extension_check(:remove_attachments, { :config => method_config })
        logger.info("Removing attached data from source configuration")
      
        locations = yield(method_config) if block_given?
      end
    else
      logger.warn("Can not remove attached data from source configuration")
    end
    locations  
  end
end
end
end

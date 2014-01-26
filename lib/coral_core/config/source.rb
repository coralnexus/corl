
module Coral
class Config
class Source < Config
  
  include Mixin::SubConfig

  #-----------------------------------------------------------------------------
  
  def initialize(data = {}, defaults = {}, force = true)
    super(data, defaults, force)
    
    logger.debug("Initializing source sub configuration")
    init_subconfig(true)
    
    unless _get(:project)
      logger.info("Setting source configuration project")
      _set(:project, Coral.project({
        :directory => _delete(:directory, Dir.pwd),
        :url       => _delete(:url),
        :revision  => _delete(:revision)
      }, _delete(:project_provider)))
    end
    
    _init(:autoload, true)
    _init(:autosave, true)
    _init(:autocommit, true)
    _init(:commit_message, 'Saving state')
    
    self.config_file = _get(:config_file, '')
  end
  
  #---
  
  def self.finalize(file_name)
    proc do
      logger.debug("Finalizing file: #{file_name}")
      Util::Disk.close(file_name)
    end
  end
  
  #---
  
  def inspect
    "#<#{self.class}: #{@absolute_config_file}>"
  end
  
  #---
  
  def logger
    return Coral.logger
  end
     
  #-----------------------------------------------------------------------------
  # Checks
  
  def can_persist?
    success = project.can_persist?
    success = false if Util::Data.empty?(@absolute_config_file)
    return success
  end
      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def autoload(default = false)
    return _get(:autoload, default)
  end
  
  #---
  
  def autoload=autoload
    _set(:autoload, test(autoload))
  end
   
  #---
  
  def autosave(default = false)
    return _get(:autosave, default)
  end
  
  #---
  
  def autosave=autosave
    _set(:autosave, test(autosave))
  end
   
  #---
  
  def autocommit(default = false)
    return _get(:autocommit, default)
  end
  
  #---
  
  def autocommit=autocommit
    _set(:autocommit, test(autocommit))
  end
   
  #---
  
  def commit_message(default = false)
    return _get(:commit_message, default)
  end
  
  #---
  
  def commit_message=commit_message
    _set(:commit_message, string(commit_message))
  end
  
  #---
  
  def project(default = nil)
    return _get(:project, default)
  end
  
  #---
  
  def config_file(default = nil)
    return _get(:config_file, default)
  end
  
  #---
  
  def config_file=file
    unless Util::Data.empty?(file)
      _set(:config_file, Util::Disk.filename(file))
    end    
    set_absolute_config_file
  end

  #---
 
  def set_absolute_config_file
    if Util::Data.empty?(project.directory) || Util::Data.empty?(config_file)
      logger.debug("Clearing absolute configuration file path: (dir: #{project.directory} - file: #{config_file})")      
      @absolute_config_file = ''
    else 
      @absolute_config_file = File.join(project.directory, config_file)      
      logger.debug("Setting absolute configuration file path to #{@absolute_config_file}")
      
      ObjectSpace.define_finalizer(self, self.class.finalize(@absolute_config_file))
    end
    load if autoload
    return self
  end
  protected :set_absolute_config_file
  
  #---
  
  def set_location(directory)
    if directory && directory.is_a?(Coral::Plugin::Project)
      logger.debug("Setting source project directory from other project at #{directory.directory}")  
      project.set_location(directory.directory)
      
    elsif directory && directory.is_a?(String) || directory.is_a?(Symbol)
      logger.debug("Setting source project directory to #{directory}")  
      project.set_location(directory.to_s)
    end
    set_absolute_config_file if directory
  end
  
  #-----------------------------------------------------------------------------
    
  def set(keys, value = '', options = {})
    super(keys, value)
    save(options) if autosave
    return self
  end
   
  #---
   
  def delete(keys, options = {})
    super(keys)
    save(options) if autosave
    return self
  end
  
  #---
  
  def clear(options = {})
    super
    save(options) if autosave
    return self
  end

  #-----------------------------------------------------------------------------
  # Import / Export
  
  def import(properties, options = {})
    super(properties, options)
    save(options) if autosave
    return self
  end
      
  #-----------------------------------------------------------------------------
  # Configuration loading / saving
    
  def load(options = {})
    local_config = Config.ensure(options)
    
    if can_persist? && File.exists?(@absolute_config_file)
      logger.info("Loading source configuration from #{@absolute_config_file}") 
      
      raw = Util::Disk.read(@absolute_config_file)    
      if raw && ! raw.empty?
        logger.debug("Source configuration file contents: #{raw}") 
        
        config.clear if local_config.get(:override, false)
        properties = Coral.translator(local_config, _get(:translator_provider)).parse(raw)
        
        logger.debug("Source configuration parsed properties: #{properties}")        
        config.import(properties, local_config)
      end
    else
      logger.warn("Loading of source configuration from #{@absolute_config_file} failed")
    end
    return self
  end
   
  #---
    
  def save(options = {})
    local_config = Config.ensure(options)
    
    if can_persist?
      logger.info("Loading source configuration from #{@absolute_config_file}")
      logger.debug("Source configuration properties: #{config.export}") 
      
      rendering = Coral.translator(local_config, _get(:translator_provider)).generate(config.export)
      if rendering && ! rendering.empty?
        Util::Disk.write(@absolute_config_file, rendering)
        logger.debug("Source configuration rendering: #{rendering}") 
        
        project.commit(@absolute_config_file, local_config) if autocommit
      end
    else
      logger.warn("Can not save source configuration to #{@absolute_config_file}")
    end
    return self
  end
  
  #---
  
  def rm(options = {})
    local_config = Config.ensure(options)
    
    if can_persist?
      logger.info("Removing source configuration at #{@absolute_config_file}")
      
      config.clear
      File.delete(@absolute_config_file)
      project.commit(@absolute_config_file, local_config) if autocommit
    else
      logger.warn("Can not remove source configuration at #{@absolute_config_file}")
    end  
  end
end
end
end

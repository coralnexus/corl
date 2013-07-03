
module Coral
class Config
class File < Config

  #-----------------------------------------------------------------------------
  
  def initialize(data = {}, defaults = {}, force = true)
    super(data, defaults, force)
    
    unless _get(:project)
      _set(:project, Coral.project({
        :directory => _delete(:directory, Dir.pwd),
        :url       => _delete(:url),
        :revision  => _delete(:revision)
      }))
    end
    
    unless _get(:config)
      _set(:config, Config.new)
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
      Util::Disk.close(file_name)
    end
  end
  
  #---
  
  def inspect
    "#<#{self.class}: #{@absolute_config_file}>"
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
      @absolute_config_file = ''
    else 
      @absolute_config_file = File.join(project.directory, config_file)
      ObjectSpace.define_finalizer(self, self.class.finalize(@absolute_config_file))
    end
    load if autoload
    return self
  end
  protected :set_absolute_config_file
  
  #---
  
  def set_location(directory)
    if directory && directory.is_a?(Coral::Plugin::Project)
      project.set_location(directory.directory)
    elsif directory && directory.is_a?(String) || directory.is_a?(Symbol)
      project.set_location(directory.to_s)
    end
    set_absolute_config_file if directory
  end
  
  #---
  
  def config(default = nil)
    return _get(:config, default)
  end
  
  #---
  
  def config=config
    _set(:config, config)
  end
  
  #-----------------------------------------------------------------------------
  
  def _get(keys, default = nil, format = false)
    return Config.instance_method(:get).bind(self).call(keys, default, format)  
  end
  protected :_get
  
  #---
  
  def get(keys, default = nil, format = false)
    return config.get(keys, default, format)
  end
  
  #---
  
  def _init(keys, default = nil)
    return _set(keys, _get(keys, default))
  end
  protected :_init

  #---
 
  def _set(keys, value = '', options = {})
    return Config.instance_method(:set).bind(self).call(keys, value, options)  
  end
  protected :_set
  
  #---
    
  def set(keys, value = '', options = {})
    config.set(keys, value, options)
    save(options) if autosave
    return self
  end
  
  #---
 
  def _delete(keys, options = {})
    return Config.instance_method(:delete).bind(self).call(keys, options)  
  end
  protected :_delete
  
  #---
   
  def delete(keys, options = {})
    config.delete(keys, options)
    save(options) if autosave
    return self
  end
 
  #---
 
  def _clear(options = {})
    return Config.instance_method(:clear).bind(self).call(options)  
  end
  protected :_clear
  
  #---
  
  def clear(options = {})
    config.clear(options)
    save(options) if autosave
    return self
  end

  #-----------------------------------------------------------------------------
  # Import / Export
  
  def import(properties, options = {})
    config.import(properties, options)
    save(options) if autosave
    return self
  end
  
  #---
  
  def export
    return config.export
  end
      
  #-----------------------------------------------------------------------------
  # Configuration loading / saving
    
  def load(options = {})
    local_config = Config.ensure(options)
    
    if can_persist? && File.exists?(@absolute_config_file)
      json_text = Util::Disk.read(@absolute_config_file)    
      if json_text && ! json_text.empty?
        config.clear if local_config.get(:override, false)
        config.import(Util::Data.parse_json(json_text), local_config)
      end
    end
    return self
  end
   
  #---
    
  def save(options = {})
    local_config = Config.ensure(options)
    
    if can_persist?
      json_text = Util::Data.to_json(config.export, true)
      if json_text && ! json_text.empty?
        Util::Disk.write(@absolute_config_file, json_text)
        project.commit(@absolute_config_file, local_config) if autocommit
      end
    end
    return self
  end
  
  #---
  
  def delete(options = {})
    local_config = Config.ensure(options)
    
    if can_persist?
      config.clear
      File.delete(@absolute_config_file)
      project.commit(@absolute_config_file, local_config) if autocommit
    end  
  end
end
end
end

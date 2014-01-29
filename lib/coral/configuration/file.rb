
module Coral
module Configuration
class File < Plugin::Configuration

  #-----------------------------------------------------------------------------
  # Configuration plugin interface
  
  def normalize
    super
    
    logger.info("Setting source configuration project")
    @project = Coral.project(extended_config(:project, {
      :directory => _delete(:directory, Dir.pwd),
      :url       => _delete(:url),
      :revision  => _delete(:revision)
    }), _delete(:project_provider))
    
    _init(:autocommit, true)
    _init(:commit_message, 'Saving state')
    
    self.translator = _get(:translator, nil)  
    self.file_name  = _get(:file_name, '')    
  end
  
  #--- 
  
  def self.finalize(file_name)
    proc do
      logger.debug("Finalizing file: #{file_name}")
      Util::Disk.close(file_name)
    end
  end
     
  #-----------------------------------------------------------------------------
  # Checks
  
  def can_persist?
    success = project.can_persist?
    success = false if Util::Data.empty?(location)
    return success
  end
      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers

  def project
    return @project
  end
   
  #---
  
  def translator(default = :json)
    return _get(:translator, default)
  end
  
  def translator=translator
    _set(:autosave, string(translator)) if translator
  end
    
  #---
  
  def file_name(default = nil)
    return _get(:file_name, default)
  end
  
  def file_name=file
    unless Util::Data.empty?(file)
      _set(:file_name, Util::Disk.filename(file))
    end    
    set_absolute_location
  end
  
  #---
  
  def location
    _get(:location, '')
  end

  def set_location(directory)
    if directory && directory.is_a?(Coral::Plugin::Project)
      logger.debug("Setting source project directory from other project at #{directory.directory}")  
      project.set_location(directory.directory)
      
    elsif directory && directory.is_a?(String) || directory.is_a?(Symbol)
      logger.debug("Setting source project directory to #{directory}")  
      project.set_location(directory.to_s)
    end
    set_absolute_location if directory
  end
   
  #---
  
  def autocommit(default = false)
    return _get(:autocommit, default)
  end
  
  def autocommit=autocommit
    _set(:autocommit, test(autocommit))
  end
   
  #---
  
  def commit_message(default = false)
    return _get(:commit_message, default)
  end
  
  def commit_message=commit_message
    _set(:commit_message, string(commit_message))
  end
   
  #-----------------------------------------------------------------------------
  # Configuration loading / saving
    
  def load(options = {})
    return super do |method_config, properties|
      if Util::Disk.exists?(location)
        logger.info("Loading source configuration from #{location}") 
      
        parser = Coral.translator(method_config, translator)
        raw    = Util::Disk.read(location)    
        
        if parser && raw && ! raw.empty?
          logger.debug("Source configuration file contents: #{raw}") 
          properties = parser.parse(raw)
        end
      end
      properties
    end
  end
   
  #---
    
  def save(options = {})
    return super do |method_config|    
      logger.debug("Fetching source configuration from #{location}")
      
      if renderer = Coral.translator(method_config, translator)
        rendering = renderer.generate(config.export)
        
        Util::Disk.write(location, rendering)
        logger.debug("Source configuration rendering: #{rendering}") 
        
        project.commit(location, method_config) if autocommit
      end
    end
  end
  
  #---
  
  def delete(options = {})
    return super do |method_config| 
      Util::Disk.delete(location)
      project.commit(location, method_config) if autocommit
    end 
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
   
  def set_absolute_location
    if Util::Data.empty?(project.directory) || Util::Data.empty?(file_name)
      logger.debug("Clearing absolute configuration file path: (dir: #{project.directory} - file: #{file_name})")      
      _set(:location , '')
    else 
      _set(:location, Util::Disk.filename([ project.directory, file_name ]))      
      logger.debug("Setting absolute configuration file path to #{location}")
      
      ObjectSpace.define_finalizer(self, self.class.finalize(location))
    end
    load if autoload
  end
  protected :set_absolute_location
end
end
end


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
    success
  end
      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers

  def project
    @project
  end
   
  #---
  
  def translator(default = :json)
    _get(:translator, default)
  end
  
  def translator=translator
    _set(:autosave, string(translator)) if translator
  end
    
  #---
  
  def file_name(default = nil)
    _get(:file_name, default)
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
    _get(:autocommit, default)
  end
  
  def autocommit=autocommit
    _set(:autocommit, test(autocommit))
  end
   
  #---
  
  def commit_message(default = false)
    _get(:commit_message, default)
  end
  
  def commit_message=commit_message
    _set(:commit_message, string(commit_message))
  end
    
  #-----------------------------------------------------------------------------
  # Configuration loading / saving
    
  def load(options = {})
    super do |method_config, properties|
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
    super do |method_config|    
      logger.debug("Fetching source configuration from #{location}")
      
      success = false
      
      if renderer = Coral.translator(method_config, translator)
        rendering = renderer.generate(config.export)
        
        if Util::Disk.write(location, rendering)
          commit_files = [ location, method_config.get_array(:files) ].flatten
          
          logger.debug("Source configuration rendering: #{rendering}")        
          success = update_project(array(method_config.delete(:files)), method_config)
        end
      end
      success
    end
  end
  
  #---
  
  def remove(options = {})
    super do |method_config|
      success = false 
      if Util::Disk.delete(location)
        success = update_project([], method_config)
      end
      success
    end
  end
  
  #---
  
  def attach(type, name, file, options = {})
    super do |method_config|
      attach_path = Util::Disk.filename([ project.directory, type.to_s ])
      file        = ::File.expand_path(file)
      success     = true
      
      logger.debug("Attaching file #{file} to configuration at #{attach_path}")
    
      file.match(/(\.[A-Za-z0-9]+)?$/)
      attach_ext = $1 || ''
      
      new_file = project.local_path(Util::Disk.filename([ attach_path, "#{name}#{attach_ext}" ]))
      dbg(new_file)
    
      FileUtils.mkdir(attach_path) unless Dir.exists?(attach_path)
      FileUtils.cp(file, new_file)
    
      logger.debug("Attaching file to project as #{new_file}")
      success = update_project(new_file, method_config)
          
      success ? new_file : nil
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
  
  #---
  
  def update_project(files = [], options = {})
    config  = Config.ensure(options)
    success = true
    
    if autocommit || config.get(:commit, false)
      commit_files = location
      commit_files = [ location, array(files) ].flatten unless files.empty?
          
      logger.info("Committing changes to configuration files")        
      success = project.commit(commit_files, config) if autocommit
          
      if success && remote = config.get(:remote, nil)
        logger.info("Pushing configuration updates to remote #{remote}")
        success = project.pull(remote, config)
        success = project.push(remote, config) if success       
      end
    end
    success
  end
end
end
end

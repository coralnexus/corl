
module Coral
module Plugin
class Project < Base
  
  @@projects = {}
  
  #---
  
  def self.collection
    return @@projects
  end
     
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def self.open(directory, options = {})
    config = Config.ensure(options)
    
    directory = Util::Disk.filename(directory)
    
    if ! @@projects.has_key?(directory) || config.get(:reset, false)
      return new(config.import({
        :directory => directory
      }))
    end
    return @@projects[directory]
  end
 
  #-----------------------------------------------------------------------------
  # Project plugin interface

       
  #-----------------------------------------------------------------------------
  # Checks
   
  def can_persist?
    return top?(directory) if directory
    return false
  end
 
  #---
          
  def top?(path)
    return true if File.directory?(path)
    return false
  end

  #---
      
  def project_directory?(path, require_top_level = false)
    path = File.expand_path(path)    
    return true if File.directory?(path) && (! require_top_level || top?(path))
    return false
  end
   
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
  
  def url(default = nil)
    return get(:url, default)
  end
  
  #---
  
  def directory(default = nil)
    return get(:directory, default)
  end
   
  #---
  
  def path
    if parent.nil?
      return directory  
    end
    return directory.gsub(parent.directory + File::SEPARATOR, '')
  end
  
  #---
   
  def set_location(directory)
    @@projects.delete(get(:directory)) if get(:directory)
    
    if Util::Data.empty?(directory)
      set(:directory, Dir.pwd)
    else
      set(:directory, Util::Disk.filename(directory))
    end
    @@projects[get(:directory)] = self
    
    init_parent
    return self
  end
  
  #---
  
  def parent(default = nil)
    return get(:parent, default)
  end

  #---
  
  def init_parent
    delete(:parent)
        
    unless top?(directory)
      search_dir = directory
      
      while File.directory?((search_dir = File.expand_path('..', search_dir)))
        if project_directory?(search_dir)
          set(:parent, self.class.open(search_dir))                
          break;
        end        
      end      
    end
    return self       
  end
  protected :init_parent
  
  #---
  
  def revision(default = nil)
    return get(:revision, default)
  end
   
  #-----------------------------------------------------------------------------
  # Plugin operations
  
  def register
    super
  end
 
  #-----------------------------------------------------------------------------
  # Project operations
   
  def fetch(options = {})
    # implement in sub classes
  end
  
  #---
  
  def update(options = {})
    # Implement in sub classes
  end
  
  #---
  
  def delete(options = {})
    # Implement in sub classes
  end
end
end
end

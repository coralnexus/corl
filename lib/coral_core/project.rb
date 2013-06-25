
module Coral
module Project
  
  #-----------------------------------------------------------------------------
  # General connector utilities
  
  def self.instance(project, options = {})
    return nil unless project
    
    config = Config.ensure(options)
    
    unless project.is_a?(Hash)
      project = {
        :url      => project,
        :revision => nil
      }
    end   
    
    project = Core.symbol_map(project)
    
    if match = project[:url].match(/^([a-zA-Z0-9_]+)::(.+)$/)
      type, url = match.captures
      project[:class] = type.strip.capitalize
      project[:url]   = url
    else
      project[:class] = 'Git'
    end
       
    return Project::const_get(project[:class]).new(project, options)
  end

  #-----------------------------------------------------------------------------
  # Base connector
  
class Base < Config
  # All Connector classes should directly or indirectly extend Base
  
  def intialize(project = {}, defaults = {}, force = true)
    super(project, defaults, force)
    normalize
  end
  
  #---
  
  def normalize
    # Implement in sub classes for any post initialization processing 
  end
  protected :normalize
end
end
end
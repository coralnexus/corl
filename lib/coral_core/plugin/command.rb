
module Coral
module Plugin
class Command < Base

  #-----------------------------------------------------------------------------
  # Command plugin interface
  
  def initialized?(options = {})
    return super(options)    
  end
  
  #---
  
  def to_s
    return build(properties)
  end
  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
  
  def command=command
    set(:command, command)
  end
  
  #---
  
  def args(default = nil)
    return array(get(:args, default)) 
  end
  
  #---
  
  def args=args
    set(:args, array(args))
  end
  
  #---
  
  def flags(default = nil)
    return array(get(:flags, default)) 
  end
  
  #---
  
  def flags=flags
    set(:flags, array(flags))
  end
  
  #---
  
  def data(default = nil)
    return hash(get(:data, default)) 
  end
  
  #---
  
  def data=data
    set(:data, hash(data))
  end
  
  #---
  
  def subcommand=subcommand
    unless Util::Data.empty?(subcommand)
      set(:subcommand, new(hash(subcommand)))
    end
  end
  
  #-----------------------------------------------------------------------------
  # Plugin operations


  #-----------------------------------------------------------------------------
  # Command operations
  
  def build(components = {}, overrides = nil, override_key = false)
    return '' # Implement in sub classes
  end
  
  #---
  
  def exec!(options = {}, overrides = nil)
    # Implement in sub classes (don't forget the yield!)
    return true
  end
    
  #---
  
  def exec(options = {}, overrides = nil)
    return exec!(options, overrides)
  end
end
end
end

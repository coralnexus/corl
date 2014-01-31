
module Coral
module Util
class Process
  
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(name, options = {}, &code)
    @name    = name
    @options = Util::Data.hash(options)   
    @code    = code
  end
      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  attr_reader :name
  
  #---
  
  # Needed for vagrant support
  def provider_options
    return {
      :parallel => true
    }
  end
  
  #-----------------------------------------------------------------------------
  # Operations
  
  # Needed for vagrant support
  def action(action_name, options = {})
    if action_name == :run
      run(options)  
    end
    # Nothing else supported
  end
  
  #---
  
  def run(options = {})
    @code.call(Util::Data.merge([ @options, options ], true))
  end  
end
end
end

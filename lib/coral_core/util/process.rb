
module Coral
module Util
class Process
  
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(name, &code)
    @name = name   
    @code = code
  end
      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  attr_reader :name
  
  #-----------------------------------------------------------------------------
  # Actions
  
  def action(action_name, options = {})
    if action_name == :run
      run(options)  
    end
  end
  
  #---
  
  def run(options = {})
    @code.call(options)
  end  
end
end
end
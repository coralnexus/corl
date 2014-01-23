
module Coral
module Plugin
class Action < Base
  
  @@register = {}

  #-----------------------------------------------------------------------------
  # Action plugin interface
  
  def self.actions
    return @@register
  end
  
  #---
  
  def normalize
    @@register[plugin_provider] = self
    
    parse(get_array(:args, []))
  end
  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
  
  def processed?
    return get(:processed, false)
  end
  
  #---
  
  def options
    return get_hash(:options, {})
  end
  
  #---
  
  def arguments
    return get_hash(:arguments, {})
  end
   
  #---
  
  def help
    return @parser.help if @parser
    return ''
  end

  #-----------------------------------------------------------------------------
  # Operations
  
  def parse(args)
    @parser = nil    
    @parser = yield if block_given?
    
    if @parser && @parser.processed
      set(:processed, true)
      set(:options, @parser.options)
      set(:arguments, @parser.arguments)
    end 
    return self  
  end
  
  #---
  
  def execute
    success = false
    if processed?
      success = yield if block_given?    
    end
    return success
  end
  
  #-----------------------------------------------------------------------
  # Output
        
  def info(name, options = {})
    ui.info(I18n.t(name, Util::Data.merge([ self.options, arguments, options ], true)))
  end
        
  #---
       
  def warn(name, options = {})
    ui.warn(I18n.t(name, Util::Data.merge([ self.options, arguments, options ], true)))  
  end
        
  #---
        
  def error(name, options = {})
    ui.error(I18n.t(name, Util::Data.merge([ self.options, arguments, options ], true)))  
  end
        
  #---
        
  def success(name, options = {})
    ui.success(I18n.t(name, Util::Data.merge([ self.options, arguments, options ], true)))  
  end
end
end
end

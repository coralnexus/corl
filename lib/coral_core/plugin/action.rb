
module Coral
module Plugin
class Action < Base

  #-----------------------------------------------------------------------------
  # Action plugin interface
  
  def normalize
    parse(get_array(:args))
  end
  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
  
  def quiet?
    return get(:quiet, false)
  end
  
  #---
  
  def processed?
    return get(:processed, false)
  end
  
  #---
  
  def options
    return get_hash(:options)
  end
  
  #---
  
  def arguments
    return get_hash(:arguments)
  end
   
  #---
  
  def help
    return @parser.help if @parser
    return ''
  end

  #-----------------------------------------------------------------------------
  # Operations
  
  def parse(args, banner = '')
    
    logger.info("Parsing action #{plugin_provider} with: #{args.inspect}")
    
    @parser = Util::CLI::Parser.new(args, banner) do |parser| 
      yield(parser) if block_given?
      extension(:parse, { :parser => parser })
    end
    
    if @parser 
      if @parser.processed
        set(:processed, true)
        set(:options, @parser.options)
        set(:arguments, @parser.arguments)
        
        logger.debug("Parse successful: #{export.inspect}")
        
      elsif @parser.options[:help] && ! quiet?
        puts I18n.t('coral.core.exec.help.usage') + ': ' + @parser.help + "\n"
        
      else
        if @parser.options[:help]
          logger.debug("Help wanted but running in silent mode")
        else
          logger.warn("Parse failed for unknown reasons")
        end
      end
    end 
    return self  
  end
  
  #---
  
  def execute
    success = false
    
    logger.info("Executing action #{plugin_provider}")
    
    begin
      if processed?
        success = extension(:exec_init) do |op, results|
          if op == :reduce
            ! results.values.include?(false)
          else
            results ? true : false
          end
        end
        
        if success.nil? || success
          success = yield if block_given?
        end
        
        extension(:exec_exit, { :success => success })    
      end
    ensure
      cleanup
    end
    
    logger.warn("Execution failed for #{plugin_provider} with #{export.inspect}") if processed? && ! success  
    return success
  end
  
  #---
  
  def cleanup
    logger.info("Running cleanup for action #{plugin_provider}")
    
    # Nothing to do right now
    extension(:cleanup)
  end
  
  #-----------------------------------------------------------------------
  # Output
        
  def info(name, options = {})
    ui.info(I18n.t(name, Util::Data.merge([ self.options, arguments, options ], true))) unless quiet?
  end
        
  #---
       
  def warn(name, options = {})
    ui.warn(I18n.t(name, Util::Data.merge([ self.options, arguments, options ], true))) unless quiet?  
  end
        
  #---
        
  def error(name, options = {})
    ui.error(I18n.t(name, Util::Data.merge([ self.options, arguments, options ], true))) unless quiet?  
  end
        
  #---
        
  def success(name, options = {})
    ui.success(I18n.t(name, Util::Data.merge([ self.options, arguments, options ], true))) unless quiet?  
  end
end
end
end

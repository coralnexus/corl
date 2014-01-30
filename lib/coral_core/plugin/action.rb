
module Coral
module Plugin
class Action < Base
  
  include Mixin::CLI::Node

  #-----------------------------------------------------------------------------
  # Action plugin interface
  
  def normalize
    parse(get_array(:args))
  end
  
  #-----------------------------------------------------------------------------
  # Checks
  
  def quiet?
    get(:quiet, false)
  end
  
  #---
  
  def processed?
    get(:processed, false)
  end
  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
  
  def params
    get_array(:params)
  end
  
  #--
  
  def options
    get_hash(:options)
  end
  
  #---
  
  def arguments
    get_hash(:arguments)
  end
   
  #---
  
  def help
    return @parser.help if @parser
    ''
  end

  #-----------------------------------------------------------------------------
  # Operations
  
  def parse(args, banner = '')    
    logger.info("Parsing action #{plugin_provider} with: #{args.inspect}")
    
    set(:params, array(args))
    
    @parser = Util::CLI::Parser.new(args, banner) do |parser| 
      yield(parser) if block_given?
      node_options(parser)
      
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
    self  
  end
  
  #---
  
  def execute
    logger.info("Executing action #{plugin_provider}")
    
    if processed?
      status = node_exec do |node, network|
        hook_config = { :node => node, :network => network }
        
        begin
          status = yield(node, network) if extension_check(:exec_init, hook_config) && block_given?
          status = extension_set(:exec_exit, status, hook_config)
          
        ensure
          cleanup
        end
        status
      end
    else
      if @parser.options[:help]
        status = Coral.code.help_wanted
      else
        status = Coral.code.action_unprocessed
      end
    end
    
    code_name = Codes.index(status)
    logger.warn("Execution failed for #{plugin_provider} with status #{status} (#{code_name}): #{export.inspect}") if processed? && status > 1 
    
    status
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


module Coral
module Plugin
class Action < Base
  
  include Mixin::CLI::Node

  #-----------------------------------------------------------------------------
  # Action plugin interface
  
  def self.exec_safe(provider, options)
    begin
      logger = Coral.logger
      
      logger.debug("Running coral action #{provider} with #{options.inspect}")
      exit_status = Coral.action(provider, options).execute
      
    rescue Exception => error
      logger.error("Coral action #{provider} experienced an error:")
      logger.error(error.inspect)
      logger.error(error.message)
      logger.error(Coral::Util::Data.to_yaml(error.backtrace))

      Coral.ui.error(error.message, { :prefix => false }) if error.message
  
      exit_status = error.status_code if error.respond_to?(:status_code)
    end

    exit_status = Coral.code.unknown_status unless exit_status.is_a?(Integer)
    exit_status  
  end
  
  def self.exec(provider, options, quiet = true)
    exec_safe(provider, { :settings => Config.ensure(options), :quiet => quiet })
  end
  
  def self.exec_cli(provider, args, quiet = false)
    exec_safe(provider, { :args => args, :quiet => quiet })
  end
  
  #---
  
  def normalize
    args = array(delete(:args, []))
    
    if get(:settings, nil)
      set(:processed, true)  
    else
      set(:settings, {})
      parse(args)
    end
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
  
  def settings
    get(:settings)
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
    
    @parser = Util::CLI::Parser.new(args, banner) do |parser| 
      yield(parser) if block_given?
      node_options(parser)
      
      extension(:parse, { :parser => parser })
    end
    
    if @parser 
      if @parser.processed
        set(:processed, true)
        set(:settings, Config.new(Util::Data.merge([ @parser.options, @parser.arguments ], true)))
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
          status = Coral.code.success
          status = yield(node, network, status) if block_given? && extension_check(:exec_init, hook_config)
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
    
    yield if block_given?
    
    # Nothing to do right now
    extension(:cleanup)
  end
  
  #-----------------------------------------------------------------------------
  # Output
        
  def info(name, options = {})
    ui.info(I18n.t(name, Util::Data.merge([ settings.export, options ], true))) unless quiet?
  end
        
  #---
       
  def warn(name, options = {})
    ui.warn(I18n.t(name, Util::Data.merge([ settings.export, options ], true))) unless quiet?  
  end
        
  #---
        
  def error(name, options = {})
    ui.error(I18n.t(name, Util::Data.merge([ settings.export, options ], true))) unless quiet?  
  end
        
  #---
        
  def success(name, options = {})
    ui.success(I18n.t(name, Util::Data.merge([ settings.export, options ], true))) unless quiet?  
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def admin_exec(status)
    if Coral.admin?
      status = yield if block_given?
    else
      ui.warn("The #{plugin_provider} action must be run as a machine administrator")
      status = Coral.code.access_denied    
    end
    status
  end
end
end
end

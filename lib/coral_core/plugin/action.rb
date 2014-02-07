
module Coral
module Plugin
class Action < Base
  
  include Mixin::Action::Node

  #-----------------------------------------------------------------------------
  # Action plugin interface
  
  def self.exec_safe(provider, options)
    action_result = nil
    
    begin
      logger = Coral.logger
      
      logger.debug("Running coral action #{provider} with #{options.inspect}")
      action        = Coral.action(provider, options)
      exit_status   = action.execute
      action_result = action.result
      
    rescue Exception => error
      logger.error("Coral action #{provider} experienced an error:")
      logger.error(error.inspect)
      logger.error(error.message)
      logger.error(Coral::Util::Data.to_yaml(error.backtrace))

      Coral.ui.error(error.message, { :prefix => false }) if error.message
  
      exit_status = error.status_code if error.respond_to?(:status_code)
    end

    exit_status = Codes.new.unknown_status unless exit_status.is_a?(Integer)
    { :status => exit_status, :result => action_result }  
  end
  
  def self.exec(provider, options, quiet = true)
    exec_safe(provider, { :settings => Config.ensure(options), :quiet => quiet })
  end
  
  def self.exec_cli(provider, args, quiet = false)
    results = exec_safe(provider, { :args => args, :quiet => quiet })
    results[:status]
  end
  
  #---
  
  def normalize(usage = '')
    args = array(delete(:args, []))
    
    @codes = Codes.new
    
    self.usage = usage
    
    if get(:settings, nil)
      set(:processed, true)
      set(:settings, Config.ensure(get(:settings)))
      node_defaults  
    else
      set(:settings, Config.new)
      node_defaults
      parse_base(args)
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
  
  def usage=usage
    set(:usage, usage)
  end
  
  def usage
    get(:usage, '')
  end
  
  #---
  
  def help
    return @parser.help if @parser
    usage
  end
  
  #---
  
  def result=result
    set(:result, result)
  end
  
  def result
    get(:result, nil)
  end
  
  #-----------------------------------------------------------------------------
  # Status codes
    
  def code
    @codes
  end
  
  def codes(codes)
    hash(codes).each do |name, number|
      Codes.code(name, number)
    end
  end

  #-----------------------------------------------------------------------------
  # Operations
  
  def parse_base(args)    
    logger.info("Parsing action #{plugin_provider} with: #{args.inspect}")
    
    @parser = Util::CLI::Parser.new(args, usage) do |parser| 
      parse(parser)      
      extension(:parse, { :parser => parser })
    end
    
    if @parser 
      if @parser.processed
        set(:processed, true)
        settings.import(Util::Data.merge([ @parser.options, @parser.arguments ], true))
        logger.debug("Parse successful: #{export.inspect}")
        
      elsif @parser.options[:help] && ! quiet?
        puts I18n.t('coral.core.exec.help.usage') + ': ' + help + "\n"
        
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
  
  def parse(parser)
    #implement in sub classes  
  end
  
  #---
  
  def execute
    logger.info("Executing action #{plugin_provider}")
    
    self.result = nil
    
    if processed?
      status = node_exec do |node, network|
        hook_config = { :node => node, :network => network }
        
        begin
          status = code.success
          status = yield(node, network, status) if block_given? && extension_check(:exec_init, hook_config)
          status = extension_set(:exec_exit, status, hook_config)
        ensure
          cleanup
        end
        status
      end
    else
      if @parser.options[:help]
        status = code.help_wanted
      else
        status = code.action_unprocessed
      end
    end
    
    status = code.unknown_status unless status.is_a?(Integer)
    
    code_name = Codes.index(status)
    logger.warn("Execution failed for #{plugin_provider} with status #{status} (#{code_name}): #{export.inspect}") if processed? && status > 1 
    
    status
  end
  
  #---
  
  def run(provider, options = {}, quiet = true)
    self.class.exec(provider, options, quiet = true)
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
  
  def render(display, options = {})
    ui.info(display, options) unless quiet?
  end
  
  #---
        
  def info(name, options = {})
    ui.info(I18n.t(name, Util::Data.merge([ settings.export, options ], true))) unless quiet?
  end
  
  #---
   
  def alert(display, options = {})
    ui.warn(display, options) unless quiet?
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
      status = code.access_denied    
    end
    status
  end
end
end
end

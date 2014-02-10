
module Coral
module Plugin
class Action < Base
  
  include Mixin::Action::Node
  
  #-----------------------------------------------------------------------------
  # Default option interface
  
  class Option
    def initialize(name, type, default, &validator)
      @name      = name
      @type      = type
      @default   = default
      @validator = validator if validator
    end
    
    #---
    
    attr_reader :name, :type, :default
    
    #---
    
    def validate(value)
      success = true
      if @validator
        success = @validator.call(value, success)
      end
      success
    end
  end

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

    exit_status = Coral.code.unknown_status unless exit_status.is_a?(Integer)
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
  
  def normalize
    args = array(delete(:args, []))
       
    @action_interface = Util::Liquid.new do |method, method_args|
      options = {}
      options = method_args[0] if method_args.length > 0
      
      quiet   = true
      quiet   = method_args[1] if method_args.length > 1
      
      self.class.exec(method, options, quiet)
    end
    
    set(:config, Config.new)
    configure
    
    if get(:settings, nil)
      # Internal processing
      set(:processed, true)
      set(:settings, Config.ensure(get(:settings)))
    else
      # External processing
      set(:settings, Config.new)
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
  
  def config
    get(:config)
  end
  
  def register(name, type, default)
    name = name.to_sym
        
    if block_given?
      option = Option.new(name, type, default) do |value, success|
        yield(value, success)
      end
      config.set(name, option)
    else
      config.set(name, Option.new(name, type, default))  
    end
  end
  
  #---
  
  def ignore
    []
  end
    
  def options
    config.keys - arguments - ignore
  end
    
  def arguments
    []
  end
  
  #---
    
  def configure
    usage = "coral #{plugin_provider} "    
    arguments.each do |arg|
      usage << "<#{arg}> "
    end
    self.usage = usage
         
    node_config
    yield if block_given?
  end
  
  #---
   
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
  
  def status=status
    set(:status, status)
  end
  
  def status
    get(:status, code.success)
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
    Coral.code
  end
  
  def codes(*codes)
    Coral.codes(*codes)
  end

  #-----------------------------------------------------------------------------
  # Operations
 
  def parse_base(args)    
    logger.info("Parsing action #{plugin_provider} with: #{args.inspect}")
    
    @parser = Util::CLI::Parser.new(args, usage) do |parser|
      parse(parser)      
      extension(:parse, { :parser => parser, :config => config })
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
        
    generate = lambda do |format, name|
      formats = [ :option, :arg ]
      types   = [ :bool, :int, :float, :str, :array ]
      name    = name.to_sym
          
      if config.export.has_key?(name) && formats.include?(format.to_sym)
        option_config = config[name]
        type          = option_config.type
        default       = option_config.default
      
        if types.include?(type.to_sym)
          value_label = "#{type.to_s.upcase}"
      
          if type == :bool
            parser.send("option_#{type}", name, default, 
              "--[no-]#{name}", 
              "coral.actions.#{plugin_provider}.options.#{name}"
            )        
          elsif format == :arg
            parser.send("#{format}_#{type}", name, default, 
              "coral.actions.#{plugin_provider}.args.#{name}"
            )  
          else
            if type == :array
              parser.send("option_#{type}", name, default, 
                "--#{name} #{value_label},...", 
                "coral.actions.#{plugin_provider}.options.#{name}"
              )  
            else
              parser.send("option_#{type}", name, default, 
                "--#{name} #{value_label}", 
                "coral.actions.#{plugin_provider}.options.#{name}"
              )
            end
          end
        end           
      end
    end
     
    #---
    
    options.each do |name|
      generate.call(:option, name)  
    end
    
    arguments.each do |name|
      generate.call(:arg, name)
    end 
  end
  
  #---
  
  def validate
    success = true
    config.export.each do |name, option|
      settings.init(name, option.default)
      success = false unless option.validate(settings[name])
    end
    success
  end
  
  #---
   
  def execute
    logger.info("Executing action #{plugin_provider}")
    
    self.status = code.success
    self.result = nil
    
    if processed?
      if validate
        node_exec do |node, network|
          hook_config = { :node => node, :network => network }
        
          begin
            yield(node, network) if block_given? && extension_check(:exec_init, hook_config)
            self.status = extension_set(:exec_exit, status, hook_config)
          ensure
            cleanup
          end
        end
      else
        puts I18n.t('coral.core.exec.help.usage') + ': ' + help + "\n" unless quiet?
        self.status = code.validation_failed    
      end
    else
      if @parser.options[:help]
        self.status = code.help_wanted
      else
        self.status = code.action_unprocessed
      end
    end
    
    self.status = code.unknown_status unless status.is_a?(Integer)
    
    code_name = Codes.index(status)
    logger.warn("Execution failed for #{plugin_provider} with status #{status} (#{code_name}): #{export.inspect}") if processed? && status > 1 
    
    status
  end
  
  #---
  
  def run
    @action_interface
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
    ui.info(display, options) unless quiet? || display.empty?
  end
  
  #---
        
  def info(name, options = {})
    ui.info(I18n.t(name, Util::Data.merge([ settings.export, options ], true))) unless quiet?
  end
  
  #---
   
  def alert(display, options = {})
    ui.warn(display, options) unless quiet? || display.empty?
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
  
  def admin_exec
    if Coral.admin?
      yield if block_given?
    else
      ui.warn("The #{plugin_provider} action must be run as a machine administrator")
      self.status = code.access_denied    
    end
  end
end
end
end

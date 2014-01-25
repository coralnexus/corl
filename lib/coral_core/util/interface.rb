
module Coral
module Util
class Interface
  
  #-----------------------------------------------------------------------------
  # Properties
  
  @@logger = Log4r::Logger.new("coral::interface")
    
  if ENV['CORAL_LOG']
    @@log_level         = ENV['CORAL_LOG'].upcase
    
    @@logger.level      = Log4r.const_get(@@log_level)
    @@logger.outputters = Log4r::StdoutOutputter.new('console')
        
    Grit.debug = true if @@log_level == 'DEBUG'
  end
  
  #---

  COLORS = {
    :clear  => "\e[0m",
    :red    => "\e[31m",
    :green  => "\e[32m",
    :yellow => "\e[33m"
  }

  COLOR_MAP = {
    :warn    => COLORS[:yellow],
    :error   => COLORS[:red],
    :success => COLORS[:green]
  }

  #-----------------------------------------------------------------------------
  # Constructor
  
  def initialize(options = {})
    class_name = self.class.to_s.downcase
    
    if options.is_a?(String)
      options = { :resource => options, :logger => options }
    end
    config = Config.ensure(options)
    
    if config.get(:logger, false)
      if config[:logger].is_a?(String)
        @logger = Log4r::Logger.new(config[:logger])
      else
        @logger = config[:logger]
      end
    else
      @logger = Log4r::Logger.new(class_name)
    end
    
    @logger.level      = @@logger.level
    @logger.outputters = @@logger.outputters
    
    @resource = config.get(:resource, '')
    @color    = config.get(:color, true)
    
    @printer = config.get(:printer, :puts)
    
    @input = config.get(:input, $stdin)
    @output = config.get(:output, $stdout)
    @error = config.get(:error, $stderr)
    
    @delegate = config.get(:ui_delegate, nil)
  end

  #---
  
  def inspect
    "#<#{self.class}: #{@resource}>"
  end
   
  #-----------------------------------------------------------------------------
  # Accessors / Modifiers
  
  attr_accessor :logger, :resource, :color, :input, :output, :error, :delegate
  
  #-----------------------------------------------------------------------------
  
  def self.logger
    return @@logger
  end

  #-----------------------------------------------------------------------------
  # UI functionality

  def say(type, message, options = {})
    return @delegate.say(type, message, options) if check_delegate('say')
  
    defaults = { :new_line => true, :prefix => true }
    options = defaults.merge(options)
    printer = options[:new_line] ? :puts : :print
    channel = type == :error || options[:channel] == :error ? @error : @output

    safe_puts(format_message(type, message, options),
              :channel => channel, :printer => printer)
  end
  
  #---

  def ask(message, options = {})
    return @delegate.ask(message, options) if check_delegate('ask')

    options[:new_line] = false if ! options.has_key?(:new_line)
    options[:prefix] = false if ! options.has_key?(:prefix)

    say(:info, message, options)
    return @input.gets.chomp
  end
  
  #-----------------------------------------------------------------------------
  
  def info(message, *args)
    @logger.info("info: #{message}")
    
    return @delegate.info(message, *args) if check_delegate('info')
    say(:info, message, *args)
  end
  
  #---
  
  def warn(message, *args)
    @logger.info("warn: #{message}")
    
    return @delegate.warn(message, *args) if check_delegate('warn')
    say(:warn, message, *args)
  end
  
  #---
  
  def error(message, *args)
    @logger.info("error: #{message}")
    
    return @delegate.error(message, *args) if check_delegate('error')
    say(:error, message, *args)
  end
  
  #---
  
  def success(message, *args)
    @logger.info("success: #{message}")
    
    return @delegate.success(message, *args) if check_delegate('success')
    say(:success, message, *args)
  end
  
  #-----------------------------------------------------------------------------
  # Utilities

  def format_message(type, message, options = {})
    return @delegate.format_message(type, message, options) if check_delegate('format_message')
    
    if @resource && ! @resource.empty? && options[:prefix]
      prefix = "[#{@resource}]"
    end
    message = "#{prefix} #{message}".strip
    
    if @color
      if options.has_key?(:color)
        color = COLORS[options[:color]]
        message = "#{color}#{message}#{COLORS[:clear]}"
      else
        message = "#{COLOR_MAP[type]}#{message}#{COLORS[:clear]}" if COLOR_MAP[type]
      end
    end
    return message
  end

  #---
  
  def safe_puts(message = nil, options = {})
    return @delegate.safe_puts(message, options) if check_delegate('safe_puts')
    
    #dbg(message, 'message')
    #dbg(options, 'options')
    
    message ||= ""
    options = {
      :channel => @output,
      :printer => @printer,
    }.merge(options)

    begin
      options[:channel].send(options[:printer], message)
    rescue Errno::EPIPE
      return
    end
  end
  
  #-----------------------------------------------------------------------------
  
  def check_delegate(method)
    return ( @delegate && @delegate.respond_to?(method.to_s) )
  end
end
end
end
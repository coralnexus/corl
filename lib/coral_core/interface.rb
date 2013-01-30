
require "log4r"

module Coral
class Interface
  
  #-----------------------------------------------------------------------------
  # Properties
  
  @@logger = Log4r::Logger.new("coral::interface")
  
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
    
    if options.has_key?(:logger)
      if options[:logger].is_a?(String)
        @logger = Log4r::Logger.new(options[:logger])
      else
        @logger = options[:logger] 
      end
    else
      @logger = Log4r::Logger.new("coral::#{class_name}")
    end
    
    @resource  = ( options.has_key?(:resource) ? options[:resource] : '' )
    @color     = ( options.has_key?(:color) ? options[:color] : true )
    
    @input     = ( options.has_key?(:input) ? options[:input] : $stdin )
    @output    = ( options.has_key?(:output) ? options[:output] : $stdout )
    @error     = ( options.has_key?(:error) ? options[:error] : $stderr )
    
    @delegate  = ( options.has_key?(:ui_delegate) ? options[:ui_delegate] : nil )    
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
    options  = defaults.merge(options)
    printer  = options[:new_line] ? :puts : :print
    channel  = type == :error || options[:channel] == :error ? @error : @output

    safe_puts(format_message(type, message, options),
              :channel => channel, :printer => printer)
  end
  
  #---

  def ask(message, options = {})
    return @delegate.ask(message, options) if check_delegate('ask')

    raise Errors::UIExpectsTTY if ! @input.tty?

    options[:new_line] = false if ! options.has_key?(:new_line)
    options[:prefix]   = false if ! options.has_key?(:prefix)

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
    message = "#{prefix} #{message}"
    
    if @color
      if options.has_key?(:color)
        color   = COLORS[options[:color]]
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
    
    message ||= ""
    options   = {
      :channel  => @output,
      :printer => :puts
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
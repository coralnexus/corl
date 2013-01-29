
require "log4r"

#
# Mostly borrowed from Vagrant so we can easily integrate our UI interface 
# with it.
#
module Coral
module UI
class Basic

  #-----------------------------------------------------------------------------
  # Constructor
  
  def initialize(resource)
    @logger   = Log4r::Logger.new("coral::ui")
    @resource = resource
  end

  #-----------------------------------------------------------------------------
  # Accessors / Modifiers
  
  attr_accessor :resource

  #-----------------------------------------------------------------------------
  # UI functionality

  def say(type, message, options = {})
    defaults = { :new_line => true, :prefix => true }
    options  = defaults.merge(options)
    printer  = options[:new_line] ? :puts : :print
    channel  = type == :error || options[:channel] == :error ? $stderr : $stdout

    safe_puts(format_message(type, message, options),
              :io => channel, :printer => printer)
  end
  
  #---

  def ask(message, options = {})
    super(message)

    raise Errors::UIExpectsTTY if ! $stdin.tty?

    options[:new_line] = false if ! options.has_key?(:new_line)
    options[:prefix]   = false if ! options.has_key?(:prefix)

    say(:info, message, options)
    return $stdin.gets.chomp
  end
  
  #---
  
  def info(message, *args)
    @logger.info("info: #{message}")
    say(:info, message, *args)
  end
  
  #---
  
  def warn(message, *args)
    @logger.info("warn: #{message}")
    say(:warn, message, *args)
  end
  
  #---
  
  def error(message, *args)
    @logger.info("error: #{message}")
    say(:error, message, *args)
  end
  
  #---
  
  def success(message, *args)
    @logger.info("success: #{message}")
    say(:success, message, *args)
  end
  
  #-----------------------------------------------------------------------------
  # Utilities

  def format_message(type, message, options = {})
    message = "[#{@resource}] #{message}" if options[:prefix]
    return message
  end

  #---
  
  def safe_puts(message = nil, options = {})
    message ||= ""
    options   = {
      :io      => $stdout,
      :printer => :puts
    }.merge(options)

    begin
      options[:io].send(options[:printer], message)
    rescue Errno::EPIPE
      return
    end
  end
end

#*******************************************************************************
#*******************************************************************************

class Color < Basic
  
  #-----------------------------------------------------------------------------
  # Properties 

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
  # Utilities

  def format_message(type, message, options = nil)
    message = super

    if options.has_key?(:color)
      color   = COLORS[options[:color]]
      message = "#{color}#{message}#{COLORS[:clear]}"
    else
      message = "#{COLOR_MAP[type]}#{message}#{COLORS[:clear]}" if COLOR_MAP[type]
    end
    return message
  end
end
end
end
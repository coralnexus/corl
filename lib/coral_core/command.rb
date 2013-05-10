
module Coral
class Command < Core

  #-----------------------------------------------------------------------------
  # Properties
  
  attr_accessor :name
  attr_reader :subcommand
  
  #-----------------------------------------------------------------------------
  # Constructor / Destructor

  def initialize(options = {})
      
    if options.is_a?(String) || options.is_a?(Symbol)
      options = string(options)
      options = { :name => options, :command => options }
    end
    
    config = Config.ensure(options)
  
    super(config)
    
    @properties           = {}
    
    self.subcommand       = config.get(:subcommand, nil)
    
    @name                 = config.get(:name, '')
    
    @properties           = config.options
    @properties[:command] = executable(config)   
  end
     
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
 
  def command_base
    return @properties[:command]
  end
  
  #---
  
  def command=command
    @properties[:command] = executable({ :command => command })
  end
  
  #---
  
  def vagrant=command
    @properties[:command] = executable({ :vagrant => command })
  end
  
  #---
  
  def coral=command
    @properties[:command] = executable({ :coral => command })
  end
  
  #---
  
  def args
    return array(@properties[:args]) 
  end
  
  #---
  
  def args=args
    @properties[:args] = array(args)
  end
  
  #---
  
  def flags
    return array(@properties[:flags]) 
  end
  
  #---
  
  def flags=flags
    @properties[:flags] = array(flags)
  end
  
  #---
  
  def data
    return hash(@properties[:data]) 
  end
  
  #---
  
  def data=data
    @properties[:data] = hash(data)
  end
  
  #---
  
  def subcommand=subcommand
    unless Util::Data.empty?(subcommand)
      @properties[:subcommand] = hash(subcommand)
      @subcommand = self.class.new(@properties[:subcommand])
    end
  end

  #-----------------------------------------------------------------------------
  # Import / Export
  
  def export
    return symbol_map(@properties)
  end
 
  #-----------------------------------------------------------------------------
  # Command functions
  
  def build(components = {}, overrides = nil, override_key = false)    
    
    command            = string(components[:command])
    flags              = array( components.has_key?(:flags) ? components[:flags] : [] )
    data               = string_map(hash( components.has_key?(:data) ? components[:data] : {} ))
    args               = array( components.has_key?(:args) ? components[:args] : [] )
    subcommand         = hash( components.has_key?(:subcommand) ? components[:subcommand] : {} )
    
    override_key       = command unless override_key
    override_key       = override_key.to_sym
    
    command_string     = command.dup
    subcommand_string  = ''
    
    escape_characters  = /[\'\"]+/
    escape_replacement = '\"'
    
    dash_pattern       = /^([\-]+)/
    assignment_pattern = /\=$/
    
    # Flags
    if overrides && overrides.has_key?(:flags)
      if overrides[:flags].is_a?(Hash)
        if overrides[:flags].has_key?(override_key)
          flags = array(overrides[:flags][override_key])
        end
      else
        flags = array(overrides[:flags])
      end
    end
    flags.each do |flag|
      flag = string(flag)
      if ! flag.empty?        
        if flag.match(dash_pattern)
          dashes = $1
        else
          dashes = ( flag.size == 1 ? '-' : '--' )  
        end
        command_string << " #{dashes}#{flag}"
      end
    end
    
    # Data
    if overrides && overrides.has_key?(:data)
      if overrides[:data].has_key?(override_key)
        data = hash(overrides[:data][override_key])
      else
        override = true
        overrides[:data].each do |key, value|
          if ! value.is_a?(String)
            override = false
          end
        end
        data = hash(overrides[:data]) if override
      end
    end
    data.each do |key, value|
      key   = string(key)
      value = string(value).strip.sub(escape_characters, escape_replacement)
      
      if key.match(dash_pattern)
        dashes = $1
      else
        dashes = ( key.size == 1 ? '-' : '--' )  
      end      
      space = ( key.match(assignment_pattern) ? '' : ' ' )  
      
      command_string << " #{dashes}#{key}#{space}'#{value}'"
    end
    
    # Arguments
    if overrides && overrides.has_key?(:args)
      if overrides[:args].is_a?(Hash)
        if overrides[:args].has_key?(override_key)
          args = array(overrides[:args][override_key])
        end
      else
        args = array(overrides[:args])
      end
    end
    args.each do |arg|
      arg = string(arg).sub(escape_characters, escape_replacement)
      command_string << " '#{arg}'"
    end
    
    # Subcommand
    subcommand_overrides = ( overrides ? overrides[:subcommand] : nil )
    if subcommand && subcommand.is_a?(Hash) && ! subcommand.empty?
      subcommand_string = build(subcommand, subcommand_overrides)
    end
    
    return (command_string + ' ' + subcommand_string).strip
  end
  
  #-----------------------------------------------------------------------------
    
  def exec!(options = {}, overrides = nil)
    config = Config.ensure(options)
    
    config[:ui] = @ui
    success = Coral::Util::Shell.exec!(build(export, overrides), config) do |line|
      block_given? ? yield(line) : true
    end    
    return success
  end
  
  #---
  
  def exec(options = {}, overrides = nil)
    return exec!(options, overrides)
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def executable(options)
    config = Config.ensure(options)
    
    if config.get(:coral, false)
      return 'vagrant coral ' + config[:coral]
        
    elsif config.get(:vagrant, false)
      return 'vagrant ' + config[:vagrant]
        
    elsif config.get(:command, false)
      return config[:command]
    end
  end
end
end
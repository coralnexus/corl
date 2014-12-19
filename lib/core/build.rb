
module CORL
class Build < Core

  #-----------------------------------------------------------------------------
  # Constructor / destructor

  def initialize
    @config    = Config.new
    @locations = Config.new

    @plurals   = {}
    @types     = {}
  end

  #-----------------------------------------------------------------------------
  # Build lock

  @@build_lock = Mutex.new

  #---

  def build_lock
    @@build_lock
  end

  #-----------------------------------------------------------------------------
  # Type registration

  def register(type, plural = nil)
    type = type.to_sym

    if plural
      plural = plural.to_sym
    else
      plural = "#{type}s".to_sym
    end
    @plurals[plural] = type
    @types[type]     = Config.new
  end

  #-----------------------------------------------------------------------------
  # Package configuration

  def config
    @config
  end

  def import(config)
    @config.import(config)
  end

  #-----------------------------------------------------------------------------
  # Build locations

  def locations
    @locations
  end

  def set_location(provider, name, directory)
    @locations.set([ provider, name ], directory)
  end

  def remove_location(provider, name = nil)
    @locations.delete([ provider, name ])
  end

  #-----------------------------------------------------------------------------
  # Addon build types

  def method_missing(method, *args, &code)
    success = false
    result  = nil

    if method.to_s.match(/^set\_([a-z].*)$/)
      name = $1.to_sym

      if @types.has_key?(name) && args.length > 2
        @types[name].set([ args[0], args[1] ], args[2]) if args.length > 2
        success = true
      end

    elsif method.to_s.match(/^remove\_([a-z].*)$/)
      name = $1.to_sym

      if @types.has_key?(name) && args.length > 0
        @types[name].delete([ args[0], args[1] ])
        success = true
      end

    else
      name = @plurals[method.to_sym]

      if name && @types.has_key?(name)
        result  = @types[name]
        success = true
      end
    end
    super unless success # Raise NoMethodError
    result
  end

  #-----------------------------------------------------------------------------
  # Builders

  def manage(plugin_type, options = {})
    CORL.send(plugin_type, options)
  end
end
end
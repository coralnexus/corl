
module CORL
module Mixin
module Lookup

  #-----------------------------------------------------------------------------
  # Facter lookup

  @@facts = nil

  def fact_var
    @@facts
  end

  def fact_var=facts
    @@facts = facts
  end

  #---

  def facts(reset = false, clone = true) # Override if needed. (See node plugin)
    self.fact_var = CORL.facts if reset || fact_var.nil?
    return fact_var.clone if clone
    fact_var
  end

  #---

  def create_facts(data, reset = false)
    facts(reset, false)

    data = hash(data)
    data.each do |name, value|
      fact_var[name.to_sym] = value
    end
    create_facts_post(fact_var.clone, data.keys)
  end

  def create_facts_post(data, names)
    data
  end

  #---

  def delete_facts(names, reset = false)
    facts(reset, false)

    names = [ names ] unless names.is_a?(Array)
    data  = {}

    names.each do |name|
      name       = name.to_sym
      data[name] = fact_var.delete(name)
    end
    delete_facts_post(fact_var.clone, data)
  end

  def delete_facts_post(data, old_data)
    data
  end

  #---

  def fact(name, reset = false)
    facts(reset, false)
    fact_var[name.to_sym]
  end

  #-----------------------------------------------------------------------------
  # Hiera configuration

  @@hiera = nil

  def hiera_var
    @@hiera
  end

  def hiera_var=hiera
    @@hiera = hiera
  end

  #---

  def hiera_override_dir
    nil # Override if needed. (See network and node plugins)
  end

  #---

  def hiera_lookup_prefix
    '::'
  end

  #---

  def hiera_configuration(local_facts = {})
    Kernel.load File.join(File.dirname(__FILE__), '..', 'mod', 'hiera_backend.rb')

    backends    = CORL.value(:hiera_backends, [ "json", "yaml" ])
    config_file = CORL.value(:hiera_config_file, File.join(Hiera::Util.config_dir, 'hiera.yaml'))
    config      = {}

    if CORL.admin? && config_file && File.exist?(config_file)
      config = Hiera::Config.load(config_file)
    end

    # Need some way to tell if we have installed our own Hiera configuration.
    # TODO: Figure something else out.  This is bad.
    config = {} if config[:merge_behavior] == :native

    config[:logger] = :corl

    unless config[:merge_behavior]
      config[:merge_behavior] = "deeper"
    end

    unless config[:backends]
      config[:backends] = backends
    end

    if override_dir = hiera_override_dir
      backends.each do |backend|
        if config[:backends].include?(backend)
          backend = backend.to_sym
          config[backend] = {} unless config[backend]
          config[backend][:datadir] = override_dir
        end
      end
    end

    hiera_config = CORL.config(:hiera, config)
    loaded_facts = Util::Data.prefix(hiera_lookup_prefix, local_facts, '')

    if hiera_config[:hierarchy]
      hiera_config[:hierarchy].delete('common')
    end

    unless loaded_facts.empty?
      hiera_config[:hierarchy].collect! do |search|
        Hiera::Interpolate.interpolate(search, loaded_facts, {})
      end
    end

    unless hiera_config[:hierarchy]
      hiera_config[:hierarchy] = [ 'common' ]
    end
    unless hiera_config[:hierarchy].include?('common')
      hiera_config[:hierarchy] << 'common'
    end

    hiera_config[:hierarchy].each_with_index do |path, index|
      hiera_config[:hierarchy][index] = path.gsub('//', '/')
    end

    hiera_config.export
  end

  #---

  def hiera(reset = false)
    self.hiera_var = Hiera.new(:config => hiera_configuration(facts(reset))) if reset || hiera_var.nil?
    hiera_var
  end

  #-----------------------------------------------------------------------------
  # Configuration lookup interface

  def config_initialized?
    ready = false
    if hiera
      if CORL.admin?
        if network_path = fact(:corl_network)
          ready = File.directory?(File.join(network_path, 'config'))
        end
      else
        ready = hiera_override_dir && File.directory?(hiera_override_dir)
      end
    end
    ready
  end

  #---

  def lookup_base(properties, default = nil, options = {})
    config      = Config.new(Config.ensure(options).export)
    value       = nil

    node        = config.delete(:node, nil)

    provisioner = config.get(:provisioner, nil)

    hiera_scope = config.get(:hiera_scope, {})
    override    = config.get(:override, nil)
    context     = config.get(:context, :priority)
    debug       = config.get(:debug, false)

    return_property = config.get(:return_property, false)

    return node.lookup(properties, default, config) if node

    unless properties.is_a?(Array)
      properties = [ properties ].flatten
    end

    first_property = nil
    properties.each do |property|
      property       = property.to_sym
      first_property = property unless first_property

      if debug
        CORL.ui.info("\n", { :prefix => false })
        CORL.ui_group(Util::Console.purple(property)) do |ui|
          ui.info("-----------------------------------------------------")
        end
      end

      # Try to load facts first (these can not be overridden)
      value = fact(property)
      debug_lookup(config, property, value, "Fact lookup")

      unless value
        if config_initialized?
          # Try to find in Hiera data store
          unless hiera_scope.respond_to?('[]')
            hiera_scope = Hiera::Scope.new(hiera_scope)
          end

          hiera_scope = string_map(hiera_scope) if hiera_scope.is_a?(Hash)
          value       = hiera.lookup(property.to_s, nil, hiera_scope, override, context.to_sym)

          debug_lookup(config, property, value, "Hiera lookup")
        end

        if provisioner && value.nil?
          # Search the provisioner scope (only admins can provision a machine)
          value = CORL.provisioner({ :name => :lookup }, provisioner).lookup(property, default, config)
          debug_lookup(config, property, value, "Provisioner lookup")
        end
      end
    end
    if value.nil? # Resort to default
      value = default
      debug_lookup(config, first_property, value, "Default value")
    end
    value = Util::Data.value(value, config.get(:undefined_value, :undefined))

    if Config.get_property(first_property).nil? || value
      Config.set_property(first_property, value)
    end

    debug_lookup(config, first_property, value, 'Internalized value')

    if return_property
      return value, first_property
    end
    CORL.ui.info("\n", { :prefix => false }) if debug
    value
  end

  #---

  def lookup(properties, default = nil, options = {})
    lookup_base(properties, default, options)
  end

  #---

  def lookup_array(properties, default = [], options = {})
    config          = Config.ensure(options).defaults({ :basic => false })
    value, property = lookup(properties, nil, config.import({ :return_property => true, :context => :array }))

    if Util::Data.undef?(value)
      value = default
      debug_lookup(config, property, value, "Array default value")

    elsif ! Util::Data.empty?(default)
      if config.get(:merge, false)
        value = Util::Data.merge([default, value], config)
        debug_lookup(config, property, value, "Merged array value with default")
      end
    end

    unless value.is_a?(Array)
      value = ( Util::Data.empty?(value) ? [] : [ value ] )
    end

    value = Util::Data.value(value, config.get(:undefined_value, :undefined))
    debug_lookup(config, property, value, "Final array value")

    Config.set_property(property, value)
    CORL.ui.info("\n", { :prefix => false }) if config.get(:debug, false)
    value
  end

  #---

  def lookup_hash(properties, default = {}, options = {})
    config          = Config.ensure(options).defaults({ :basic => false })
    value, property = lookup(properties, nil, config.import({ :return_property => true, :context => :hash }))

    if Util::Data.undef?(value)
      value = default
      debug_lookup(config, property, value, "Hash default value")

    elsif ! Util::Data.empty?(default)
      if config.get(:merge, false)
        value = Util::Data.merge([default, value], config)
        debug_lookup(config, property, value, "Merged hash value with default")
      end
    end

    unless value.is_a?(Hash)
      value = ( Util::Data.empty?(value) ? {} : { :value => value } )
    end

    value = Util::Data.value(value, config.get(:undefined_value, :undefined))
    debug_lookup(config, property, value, "Final hash value")

    Config.set_property(property, value)
    CORL.ui.info("\n", { :prefix => false }) if config.get(:debug, false)
    value
  end

  #---

  def normalize(data, override = nil, options = {})
    config  = Config.ensure(options).import({ :context => :hash }).defaults({ :basic => false })
    results = {}

    unless Util::Data.undef?(override)
      case data
      when String, Symbol
        data = [ data, override ] if data != override
      when Array
        data << override unless data.include?(override)
      when Hash
        data = [ data, override ]
      end
    end

    case data
    when String, Symbol
      results = lookup(data.to_s, {}, config)

    when Array
      data.each do |item|
        if item.is_a?(String) || item.is_a?(Symbol)
          item = lookup(item.to_s, {}, config)
        end
        unless Util::Data.undef?(item)
          results = Util::Data.merge([ results, item ], config)
        end
      end

    when Hash
      results = data
    end
    results
  end

  #---

  def debug_lookup(config, property, value, label)
    if config.get(:debug, false)
      CORL.ui_group(Util::Console.cyan(property.to_s)) do |ui|
        dump = Util::Console.green(Util::Data.to_json(value, true))

        if dump.match(/\n+/)
          ui.info("#{label}:\n#{dump}")
        else
          ui.info("#{label}: #{dump}")
        end
      end
    end
  end
end
end
end

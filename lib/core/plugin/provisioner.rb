
module CORL
module Plugin
class Provisioner < Nucleon.plugin_class(:nucleon, :base)

  include Parallel

  extend Mixin::Builder::Global
  include Mixin::Builder::Instance

  #-----------------------------------------------------------------------------
  # Provisioner plugin interface

  def normalize(reload)
    super
    build_config.register(:dependency, :dependencies) if build_config
    yield if block_given?
  end

  #-----------------------------------------------------------------------------
  # Checks

  def initialized?(options = {})
  end

  #-----------------------------------------------------------------------------
  # Property accessors / modifiers

  network_settings :provisioner

  #---

  def directory=directory
    myself[:directory] = directory
  end

  def directory
    File.join(network.directory, myself[:directory])
  end

  #---

  def build_directory
    File.join(network.build_directory, 'provisioners', plugin_provider.to_s)
  end

  #---

  def gateway=gateway
    myself[:gateway] = gateway
  end

  def gateway(index = :first, reset = false)
    gateway = myself[:gateway]

    unless gateway
      gateways = package_gateways(reset)

      unless gateways.empty?
        if index == :first || index == 0
          gateway  = gateways[0]
        elsif index == :last
          gateway = gateways.pop
        elsif index.integer?
          gateway  = gateways[index]
        end
      end
    end
    gateway
  end

  def package_gateways(node, reset = false)
    gateways = []
    build_info(node, reset).each do |package_name, package_info|
      gateways << File.join('packages', id(package_name).to_s, package_info[:gateway]) if package_info.has_key?(:gateway)
    end
    gateways
  end

  #---

  def find_profiles(node, reset = false)
    allowed_profiles = []
    build_info(node, reset).each do |package_name, package_info|
      hash(package_info[:profiles]).each do |profile_name, profile_info|
        allowed_profiles << resource([ package_name, 'profile', profile_name ])
      end
    end
    allowed_profiles
  end
  protected :find_profiles

  #---

  def supported_profiles(node, profile_names = nil)
    found    = []
    profiles = build_profiles(node)

    if profile_names.nil?
      found = profiles
    else
      profile_names.each do |name|
        name = name.to_s
        if profiles.include?(name)
          found << name
        end
      end
    end
    found.empty? ? false : found
  end

  #---

  def profile_dependencies(node, profiles)
    dependencies  = build_dependencies(node)[:profile]
    profile_index = {}

    search_profiles = lambda do |profile|
      profile = profile.to_sym

      if dependencies.has_key?(profile)
        dependencies[profile].each do |parent_profile|
          search_profiles.call(parent_profile)
        end
      end
      profile_index[profile] = true
    end

    profiles.each do |profile|
      search_profiles.call(profile)
    end

    profile_index.keys
  end

  #---

  def build_dependencies(node, reset = false)
    dependencies = cache_setting(:build_dependencies, {}, :hash)
    build(node) if reset || dependencies.empty?
    symbol_map(cache_setting(:build_dependencies, {}, :hash))
  end

  #---

  def build_locations(node, reset = false)
    locations = cache_setting(:build_locations, {}, :hash)
    build(node) if reset || locations.empty?
    symbol_map(cache_setting(:build_locations, {}, :hash))
  end

  #---

  def build_info(node, reset = false)
    info = cache_setting(:build_info, {}, :hash)
    build(node) if reset || info.empty?
    symbol_map(cache_setting(:build_info, {}, :hash))
  end

  #---

  def build_profiles(node, reset = false)
    profiles = cache_setting(:build_profiles, [], :array)
    build(node) if reset || profiles.empty?
    cache_setting(:build_profiles, [], :array)
  end

  #-----------------------------------------------------------------------------
  # Provisioner operations

  def register(options = {})
    # Implement in providers
  end

  #---

  def build(node, options = {})
    config        = Config.ensure(options)
    environment   = Util::Data.ensure_value(config[:environment], node.lookup(:corl_environment))
    provider_info = network.build.config.get_hash([ :provisioners, plugin_provider ])
    combined_info = Config.new

    provider_info.each do |package, info|
      package_info = Config.new(info)
      profiles     = {}

      hash(package_info[:profiles]).each do |name, profile_info|
        profiles[profile_id(package, name)] = profile_info
      end

      package_info[:profiles] = profiles
      combined_info.import(package_info)
    end

    FileUtils.mkdir_p(build_directory)

    status  = parallel(:build_provider, provider_info, environment, combined_info)
    success = status.values.include?(false) ? false : true

    if success
      # Save the updates in the local project cache
      set_cache_setting(:build_dependencies, network.build.dependencies.export)
      set_cache_setting(:build_locations, network.build.locations.export)
      set_cache_setting(:build_info, provider_info)
      set_cache_setting(:build_profiles, find_profiles(node))
    end
    success
  end

  #---

  def build_provider(package, info, environment, combined_info)
    profiles = hash(info[:profiles])
    status = parallel(:build_profile, profiles, id(package), environment, hash(combined_info[:profiles]))
    status.values.include?(false) ? false : true
  end

  def build_profile(name, info, package, environment, profiles)
    parents = []
    config  = Config.new(info)
    success = true

    while config.has_key?(:extend) do
      array(config.delete(:extend)).each do |parent|
        parent = profile_id(package, parent) unless parent.match('::')

        parents << parent
        config.defaults(profiles[parent.to_sym])
      end
    end

    build_config.set_dependency(:profile, profile_id(package, name), parents)

    success = yield(process_environment(config, environment)) if block_given?
    success
  end

  #---

  def lookup(property, default = nil, options = {})
    # Implement in providers
    nil
  end

  #---

  def provision(node, profiles, options = {})
    config   = Config.ensure(options)
    profiles = profile_dependencies(node, profiles)
    success  = true

    success = yield(profiles, config) if block_given?

    Config.save_properties(Config.get_options(:corl_log))
    success
  end

  #-----------------------------------------------------------------------------
  # Utilities

  def self.build_info(namespace, plugin_type, data)
    data = data.split(/\s*,\s*/) if data.is_a?(String)
    super(namespace, plugin_type, data)
  end

  #---

  def self.translate(data)
    options = super(data)

    case data
    when String
      options = { :profiles => array(data) }
    when Hash
      options = data
    end

    if options.has_key?(:profiles)
      if matches = translate_reference(options[:profiles])
        options[:provider] = matches[:provider]
        options[:profiles] = matches[:profiles]

        logger.debug("Translating provisioner options: #{options.inspect}")
      end
    end
    options
  end

  #---

  def self.translate_reference(reference)
    # ex: puppetnode:::profile::something,profile::somethingelse
    if reference && reference.match(/^\s*([a-zA-Z0-9_-]+):::([^\s]+)\s*$/)
      provider = $1
      profiles = $2

      logger.debug("Translating provisioner reference: #{provider} #{profiles}")

      info = {
        :provider => provider,
        :profiles => profiles.split(/\s*,\s*/)
      }

      logger.debug("Project reference info: #{info.inspect}")
      return info
    end
    nil
  end

  #---

  def translate_reference(reference)
    self.class.translate_reference(reference)
  end

  #---

  def profile_id(package, profile)
    concatenate([ package, 'profile', profile ], false)
  end
end
end
end


module CORL
module Provisioner
class Puppetnode < Nucleon.plugin_class(:CORL, :provisioner)

  @@puppet_lock = Mutex.new

  #---

  @@status = {}

  def self.status
    @@status
  end

  #---

  def self.network
    @@network
  end

  def self.node
    @@node
  end

  #-----------------------------------------------------------------------------
  # Provisioner plugin interface

  def normalize(reload)
    super do
      if CORL.log_level == :debug
        Puppet.debug = true
      end
      unless reload
        Puppet::Util::Log.newdesttype id do
          def handle(msg)
            levels = {
              :emerg => { :name => 'emergency', :send => :error },
              :alert => { :name => 'alert', :send => :error },
              :crit => { :name => 'critical', :send => :error },
              :err => { :name => 'error', :send => :error },
              :warning => { :name => 'warning', :send => :warn },
              :notice => { :name => 'notice', :send => :success },
              :info => { :name => 'info', :send => :info },
              :debug => { :name => 'debug', :send => :info }
            }
            str = msg.respond_to?(:multiline) ? msg.multiline : msg.to_s
            str = msg.source == "Puppet" ? str : "#{CORL.blue(msg.source)}: #{str}"
            level = levels[msg.level]

            if [ :warn, :error ].include?(level[:send])
              ::CORL::Provisioner::Puppetnode.status[name] = 111
            end

            CORL.ui_group("puppetnode::#{name}(#{CORL.yellow(level[:name])})", :cyan) do |ui|
              ui.send(level[:send], str)
            end
          end
        end
      end
    end
  end

  #---

  def register(options = {})
    Util::Puppet.register_plugins(Config.ensure(options).defaults({ :puppet_scope => scope }))
  end

  #-----------------------------------------------------------------------------
  # Property accessor / modifiers

  def compiler
    @compiler
  end

  #---

  def scope
    return compiler.topscope if compiler
    nil
  end

  #-----------------------------------------------------------------------------
  # Puppet initialization

  def init_puppet(node, profiles)
    Puppet.initialize_settings

    apply_environment = nil
    locations         = build_locations(node)

    environment, environment_directory = ensure_environment(node)

    Puppet::Util::Log.newdestination(id)
    Puppet::Transaction::Report.indirection.cache_class = :yaml

    Puppet[:graph] = true if CORL.log_level == :error

    Puppet[:node_terminus]         = :plain
    Puppet[:data_binding_terminus] = :corl
    Puppet[:default_file_terminus] = :file_server

    unless profiles.empty?
      modulepath = profiles.collect do |profile|
        profile_directory = File.join(network.directory, locations[:puppet_module][profile.to_sym])
        File.directory?(profile_directory) ? profile_directory : nil
      end.compact
    end

    if manifest = gateway
      if manifest.match(/^packages\/.*/)
        manifest = File.join(network.build_directory, manifest)
      else
        manifest = File.join(network.directory, directory, manifest)
      end
    end

    Puppet[:environment] = environment
    Puppet::Node::Environment.create(environment.to_sym, modulepath, manifest)
  end
  protected :init_puppet

  #---

  def get_puppet_node(environment)
    Puppet[:node_name_value] = id.to_s

    puppet_node = Puppet::Node.indirection.find(id.to_s, :environment => environment)

    puppet_node.merge(string_map(@@node.facts))
    puppet_node
  end
  protected :get_puppet_node

  #-----------------------------------------------------------------------------
  # Provisioner interface operations

  def build_profile(name, info, package, environment, profiles)
    super do |processed_info|
      package_id = id(package)
      directory  = File.join(internal_path(build_directory), package_id.to_s, name.to_s)
      success    = true

      info("Building CORL profile #{blue(name)} modules into #{green(directory)}", { :i18n => false })

      if processed_info.has_key?(:modules)
        status  = parallel(:build_module, hash(processed_info[:modules]), directory, name, environment)
        success = status.values.include?(false) ? false : true

        build_config.set_location(:puppet_module, profile_id(package, name), directory) if success
      end
      success("Build of profile #{blue(name)} finished", { :i18n => false }) if success
      success
    end
  end

  def build_module(name, project_reference, directory, profile, environment)
    module_directory      = File.join(directory, name.to_s)
    full_module_directory = File.join(network.directory, module_directory)
    module_project        = nil
    success               = true

    info("Building #{blue(profile)} Puppet module #{blue(name)} at #{purple(project_reference)} into #{green(module_directory)}", { :i18n => false })

    module_project = build_config.manage(:project, extended_config(:puppet_module, {
      :directory     => full_module_directory,
      :url           => project_reference,
      :create        => File.directory?(full_module_directory) ? false : true,
      :pull          => true,
      :internal_ip   => CORL.public_ip, # Needed for seeding Vagrant VMs
      :manage_ignore => false
    }))
    unless module_project
      warn("Puppet module #{cyan(name)} failed to initialize", { :i18n => false })
      success = false
    end
    success("Build of #{blue(profile)} #{blue(name)} finished", { :i18n => false }) if success
    success
  end

  #---

  def lookup(property, default = nil, options = {})
    Util::Puppet.lookup(property, default, Config.ensure(options).defaults({
      :provisioner  => :puppetnode,
      :puppet_scope => scope
    }))
  end

  #--

  def import(files, options = {})
    Util::Puppet.import(files, Config.ensure(options).defaults({
      :puppet_scope       => scope,
      :puppet_import_base => network.directory
    }))
  end

  #---

  def add_search_path(type, resource_name)
    Config.set_options([ :all, type ], { :search => [ resource_name.to_s ] })
  end

  #---

  def provision(node, profiles, options = {})
    super do |processed_profiles, config|
      locations = build_locations(node)
      success   = true

      include_location = lambda do |type, parameters = {}, add_search_path = false|
        classes = {}

        locations[:package].keys.reverse.each do |name|
          package_directory = locations[:package][name]
          type_gateway      = File.join(network.directory, package_directory, "#{type}.pp")
          resource_name     = resource([ name, type ])

          add_search_path(type, resource_name) if add_search_path

          if File.exists?(type_gateway)
            import(type_gateway)
            classes[resource_name] = parameters
          end

          type_directory = File.join(network.directory, package_directory, type.to_s)
          Dir.glob(File.join(type_directory, '*.pp')).each do |file|
            resource_name = resource([ name, type, File.basename(file).gsub('.pp', '') ])
            import(file)
            classes[resource_name] = parameters
          end
        end

        type_gateway = File.join(directory, "#{type}.pp")
        resource_name = resource([ plugin_name, type ])

        add_search_path(type, resource_name) if add_search_path

        if File.exists?(type_gateway)
          import(type_gateway)
          classes[resource_name] = parameters
        end

        type_directory = File.join(directory, type.to_s)

        if File.directory?(type_directory)
          Dir.glob(File.join(type_directory, '*.pp')).each do |file|
            resource_name = resource([ plugin_name, type, File.basename(file).gsub('.pp', '') ])
            import(file)
            classes[resource_name] = parameters
          end
        end
        classes
      end

      @@puppet_lock.synchronize do
        begin
          info("Starting catalog generation", { :i18n => false })

          @@status[id] = code.success
          @@network    = network
          @@node       = node

          start_time        = Time.now
          apply_environment = init_puppet(node, processed_profiles)

          Puppet.override(:environments => Puppet::Environments::Static.new(apply_environment)) do
            puppet_node = get_puppet_node(apply_environment.name)
            @compiler   = Puppet::Parser::Compiler.new(puppet_node)

            # Register Puppet module plugins
            register

            # Include defaults
            classes = include_location.call(:default, {}, true)

            # Import needed profiles
            include_location.call(:profiles, {}, false)

            processed_profiles.each do |profile|
              classes[profile.to_s] = { :require => 'Anchor[profile_start]' }
            end

            puppet_node.classes = classes

            # Compile catalog
            compiler.compile

            catalog = compiler.catalog.to_ral
            catalog.finalize
            catalog.retrieval_duration = Time.now - start_time

            unless config.get(:dry_run, false)
              info("\n", { :prefix => false, :i18n => false })
              info("Starting configuration run", { :i18n => false })

              # Configure the machine
              configurer = Puppet::Configurer.new
              if ! configurer.run(:catalog => catalog, :pluginsync => false)
                success = false
              end
            end
          end

        rescue Exception => error
          Puppet.log_exception(error)
          success = false
        end
      end

      success = false if @@status[id] != code.success
      success
    end
  end

  #-----------------------------------------------------------------------------
  # Utilities

  def ensure_environment(node)
    base_directory = Puppet[:environmentpath]
    environment    = node.lookup(:corl_environment)
    env_directory  = File.join(base_directory, environment)

    FileUtils.mkdir_p(env_directory)
    FileUtils.mkdir_p(File.join(env_directory, 'manifests'))
    FileUtils.mkdir_p(File.join(env_directory, 'modules'))
    [ environment, env_directory ]
  end
  protected :ensure_environment
end
end
end

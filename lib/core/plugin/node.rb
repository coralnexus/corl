
module CORL
module Plugin
class Node < Nucleon.plugin_class(:nucleon, :base)

  include Parallel
  external_block_exec :exec, :command, :action

  #-----------------------------------------------------------------------------
  # Node plugin interface

  def normalize(reload)
    super

    @class_color = :purple

    export.each do |name, value|
      myself[name] = value
    end

    ui.resource = Util::Console.colorize(hostname, @class_color)
    logger      = hostname

    add_groups([ "all", plugin_provider.to_s, plugin_name.to_s ])

    unless reload
      @cli_interface = Util::Liquid.new do |method, args, &code|
        result = exec({ :commands => [ [ method, args ].flatten.join(' ') ] }) do |op, data|
          code.call(op, data) if code
        end
        if result
          result = result.first
          warn(result.errors, { :i18n => false }) unless result.errors.empty?
        end
        result
      end

      @action_interface = Util::Liquid.new do |method, args, &code|
        action(method, *args) do |op, data|
          code.call(op, data) if code
        end
      end
    end
  end

  #---

  def method_missing(method, *args, &code)
    action(method, *args) do |op, data|
      code.call(op, data) if code
    end
  end

  #---

  def localize
    @local_context       = true
    myself.local_machine = create_machine(:local_machine, :physical)
  end

  #---

  def remove_plugin
    CORL.remove_plugin(local_machine) if local_machine
    CORL.remove_plugin(machine) if machine
  end

  #-----------------------------------------------------------------------------
  # Checks

  def running?
    return machine.running? if machine
    false
  end

  #---

  def local?
    @local_context ? true : false
  end

  #---

  def usable_image?(image)
    true
  end

  #-----------------------------------------------------------------------------
  # Property accessors / modifiers

  network_settings :node

  #---

  def keypair
    @keypair
  end

  def keypair=keypair
    @keypair = keypair
  end

  #---

  def machine
    @machine
  end

  def machine=machine
    @machine = machine
  end

  #---

  def local_machine
    @local_machine
  end

  def local_machine=local_machine
    @local_machine = local_machine
  end

  #---

  def id(reset = false)
    myself[:id] = machine.plugin_name if machine && ( reset || setting(:id).nil? )
    setting(:id)
  end

  #---

  def public_ip(reset = false)
    myself[:public_ip] = machine.public_ip if machine && ( reset || setting(:public_ip).nil? )
    setting(:public_ip)
  end

  def private_ip(reset = false)
    myself[:private_ip] = machine.private_ip if machine && ( reset || setting(:private_ip).nil? )
    setting(:private_ip)
  end

  #---

  def hostname
    hostname = setting(:hostname)

    unless hostname
      hostname = plugin_name
    end

    if hostname.to_s != ui.resource.to_s
      ui.resource = Util::Console.colorize(hostname, @class_color)
      logger      = hostname
    end
    hostname
  end

  #---

  def state(reset = false)
    myself[:state] = machine.state if machine && ( reset || setting(:state).nil? )
    setting(:state)
  end

  #---

  def user=user
    myself[:user] = user
  end

  def user
    myself[:user]
  end

  #---

  def ssh_port=ssh_port
    myself[:ssh_port] = ssh_port
    machine.init_ssh(ssh_port) if machine
  end

  def ssh_port
    myself[:ssh_port] = 22 if myself[:ssh_port].nil?
    myself[:ssh_port]
  end

  #---

  def home(env_var = 'HOME', reset = false)
    if reset || myself[:user_home].nil?
      myself[:user_home] = cli_capture(:echo, '$' + env_var.to_s.gsub('$', '')) if machine
    end
    myself[:user_home]
  end

  #---

  def ssh_path(home_env_var = 'HOME', reset = false)
    home = home(home_env_var, reset)
    home ? File.join(home, '.ssh') : nil
  end

  #---

  def private_key=private_key
    myself[:private_key] = private_key
  end

  def private_key
    config_key = myself[:private_key]
    return File.expand_path(config_key, network.directory) if config_key
    nil
  end

  #---

  def public_key=public_key
    myself[:public_key] = public_key
  end

  def public_key
    config_key = myself[:public_key]
    return File.expand_path(config_key, network.directory) if config_key
  end

  #---

  def machine_types # Must be set at machine level (queried)
    machine.machine_types if machine
  end

  def machine_type(reset = false)
    myself[:machine_type] = machine.machine_type if machine && ( reset || myself[:machine_type].nil? )
    machine_type          = myself[:machine_type]

    if machine_type.nil? && machine
      if types = machine_types
        unless types.empty?
          machine_type          = machine_type_id(types.first)
          myself[:machine_type] = machine_type
        end
      end
    end

    machine_type
  end

  #---

  def images(search_terms = [], options = {})
    config = Config.ensure(options)
    images = []

    if machine
      loaded_images = machine.images

      if loaded_images
        require_all = config.get(:require_all, false)

        loaded_images.each do |image|
          if usable_image?(image)
            include_image = ( search_terms.empty? ? true : require_all )
            image_text    = image_search_text(image)

            search_terms.each do |term|
              if config.get(:match_case, false)
                success = image_text.match(/#{term}/)
              else
                success = image_text.match(/#{term}/i)
              end

              if require_all
                include_image = false unless success
              else
                include_image = true if success
              end
            end

            images << image if include_image
          end
        end
      end
    end
    images
  end

  #---

  def image=image
    myself[:image] = image
  end

  def image(reset = false)
    myself[:image] = machine.image if machine && ( reset || myself[:image].nil? )
    myself[:image]
  end

  #---

  def custom_facts=facts
    myself[:facts] = hash(facts)
  end

  def custom_facts
    search(:facts, {}, :hash)
  end

  def ensure_custom_facts(facts)
    hash(facts).each do |name, value|
      set_setting([ :facts, name ], value)
    end
  end

  def remove_custom_facts(*facts)
    facts.each do |name|
      delete_setting([ :facts, name ])
    end
  end

  #---

  def profiles=profiles
    myself[:profiles] = array(profiles)
  end

  def profiles
    [ array(myself[:profiles]), lookup_array(:profiles).reverse ].flatten
  end

  #---

  def provisioner_info
    provisioner_info = {}

    # Compose needed provisioners and profiles
    profiles.each do |profile|
      if info = Plugin::Provisioner.translate_reference(profile)
        provider = info[:provider]

        provisioner_info[provider] = { :profiles => [] } unless provisioner_info.has_key?(provider)
        provisioner_info[provider][:profiles] += info[:profiles]
      end
    end
    provisioner_info
  end

  #---

  def provisioners
    provisioners = {}
    provisioner_info.each do |provider, node_profiles|
      provisioners[provider] = network.provisioners(provider)
    end
    provisioners
  end

  #---

  def build_time=time
    myself[:build] = time
  end

  def build_time
    myself[:build]
  end

  #---

  def bootstrap_script=bootstrap
    myself[:bootstrap] = bootstrap
  end

  def bootstrap_script
    myself[:bootstrap]
  end

  #---

  def agents
    hash(myself[:agents])
  end

  def agent(provider)
    search([ :agents, provider ], {}, :hash)
  end

  def add_agent(provider, settings)
    set_setting([ :agents, provider ], Config.new(settings).export)
  end

  def remove_agent(provider)
    delete_setting([ :agents, provider ])
  end

  #-----------------------------------------------------------------------------
  # Settings groups

  def machine_config
    name   = setting(:id)
    name   = nil if name.nil? || name.empty?
    config = Config.new({ :name => name })

    yield(config) if block_given?
    config
  end

  #-----------------------------------------------------------------------------
  # Machine information

  def fact_var
    @facts
  end

  def fact_var=facts
    @facts = facts
  end

  #---

  def facts(reset = false, clone = true)
    if reset || fact_var.nil?
      default_facts = extended_config(:hiera_default_facts, {
        :fqdn          => hostname,
        :hostname      => hostname.gsub(/\..*$/, ''),
        :corl_provider => plugin_provider.to_s
      })

      unless local?
        result = run.node_facts({ :quiet => true })

        if result.status == code.success
          node_facts = Util::Data.symbol_map(Util::Data.parse_json(result.errors))
        end
      end
      unless node_facts
        node_facts = local? ? Util::Data.merge([ CORL.facts, custom_facts ]) : custom_facts
      end

      self.fact_var = Config.new(node_facts).defaults(default_facts).export
    end
    return fact_var.clone if clone
    fact_var
  end

  #---

  def create_facts_post(data, names)
    fact_values = {}
    names.each do |name|
      name              = name.to_sym
      fact_values[name] = data[name]
    end
    ensure_custom_facts(fact_values)
    data
  end

  #---

  def delete_facts_post(data, old_data)
    remove_custom_facts(*old_data.keys)
    data
  end

  #---

  def hiera_var
    @hiera
  end

  def hiera_var=hiera
    @hiera = hiera
  end

  #---

  def hiera_override_dir
    network.hiera_override_dir
  end

  #---

  def lookup(property, default = nil, options = {})
    unless local?
      config = Config.ensure(options).import({ :property => property, :quiet => true })
      result = run.node_lookup(config)

      if result.status == code.success
        return Util::Data.value(Util::Data.parse_json(result.errors), default)
      end
      return default
    end
    options[:hiera_scope] = Util::Data.prefix('::', facts, '')
    lookup_base(property, default, options)
  end

  #---

  def remote_cache_setting(keys, default = nil, format = false)
    cache_id = keys.flatten.join('.')
    result   = run.node_cache({ :name => cache_id })

    if result.status == code.success
      value = Util::Data.value(Util::Data.parse_json(result.errors), default)
    else
      value = default
    end
    filter(value, format)
  end

  #---

  def set_remote_cache_setting(keys, value)
    run.node_cache({
      :name  => keys.flatten.join('.'),
      :value => Util::Data.to_json(value, false),
      :json  => true
    }).status == code.success
  end

  #---

  def delete_remote_cache_setting(keys)
    run.node_cache({
      :name   => keys.flatten.join('.'),
      :delete => true
    }).status == code.success
  end

  #---

  def clear_remote_cache
    run.node_cache({ :clear => true }).status == code.success
  end

  #-----------------------------------------------------------------------------
  # Machine operations

  def build(options = {})
    config  = Config.ensure(options)
    success = true

    # TODO: Figure out what's going on with the parallel implementation here.
    parallel_original          = ENV['NUCLEON_NO_PARALLEL']
    ENV['NUCLEON_NO_PARALLEL'] = 'true'

    status  = parallel(:build_provider, network.builders, config)
    success = false if status.values.include?(false)

    if success
      if array(config[:providers]).empty? || array(config[:providers]).include?("package")
        status  = parallel(:build_provisioners, provisioners, config)
        success = false if status.values.include?(false)
      end

      if success
        myself.build_time = Time.now.to_s if success

        if config.delete(:save, true)
          success("Saving successful build", { :i18n => false })

          success = save(extended_config(:build, {
            :message => config.get(:message, "Built #{plugin_provider} node: #{plugin_name}"),
            :remote  => config.get(:remote, :edit)
          }))
        end
      end
    end

    ENV['NUCLEON_NO_PARALLEL'] = parallel_original
    success
  end

  def build_provider(provider, plugin, config)
    if array(config[:providers]).empty? || array(config[:providers]).include?(provider.to_s)
      #info("Building #{provider} components", { :i18n => false })
      plugin.build(myself, config)
    end
  end

  def build_provisioners(provider, collection, config)
    #info("Building #{provider} provisioner collection", { :i18n => false })
    status = parallel(:build_provisioner, collection, provider, config)
    status.values.include?(false) ? false : true
  end

  def build_provisioner(name, plugin, provider, config)
    #info("Building #{provider} #{name} provisioner components", { :i18n => false })
    plugin.build(myself, config)
  end

  #---

  def attach_keys(keypair)
    base_name   = "#{plugin_provider}-#{plugin_name}"
    save_config = {
      :pull    => false,
      :push    => false,
      :message => "Updating SSH keys for node #{plugin_provider} (#{plugin_name})"
    }

    active  = machine && machine.running?
    result  = run.authorize({ :public_key => keypair.ssh_key }) if active
    success = false

    if ! active || result.status == code.success
      private_key = network.attach_data(:keys, "#{base_name}-id_#{keypair.type}", keypair.encrypted_key)
      public_key  = network.attach_data(:keys, "#{base_name}-id_#{keypair.type}.pub", keypair.ssh_key)

      if private_key && public_key
        FileUtils.chmod(0600, private_key)
        FileUtils.chmod(0644, public_key)

        myself.keypair = Util::SSH.generate({ :private_key => keypair.private_key })
        myself.keypair.store(network.key_cache_directory, plugin_name)

        save_config[:files] = [ private_key, public_key ]

        myself.private_key = private_key
        myself.public_key  = public_key

        success = save(extended_config(:key_save, save_config))
      end
    end
    success
  end

  #---

  def delete_keys
    private_key = myself[:private_key]
    public_key  = myself[:public_key]

    keys = []
    keys << private_key if private_key
    keys << public_key if public_key

    success = true

    unless keys.empty?
      files = network.delete_attachments(keys)

      if files && ! files.empty?
        delete_setting(:private_key)
        delete_setting(:public_key)

        success = save(extended_config(:key_delete, {
          :files   => [ private_key, public_key ],
          :pull    => false,
          :push    => false,
          :message => "Removing SSH keys for node #{plugin_provider} (#{plugin_name})"
        }))
      else
        success = false
      end
    end
    success
  end

  #---

  def create_machine(name, provider, options = {})
    CORL.create_plugin(:CORL, :machine, provider, extended_config(name, options).import({ :meta => { :parent => myself }}))
  end

  #---

  def create(options = {})
    success = true

    if machine
      config = Config.ensure(options)

      clear_cache

      if extension_check(:create, { :config => config })
        logger.info("Creating node: #{plugin_name}")

        yield(:config, config) if block_given?
        success = machine.create(config.export)

        if success && block_given?
          process_success = yield(:process, config)
          success         = process_success if process_success == false
        end

        if success
          extension(:create_success, { :config => config })
        end
      end
    else
      logger.warn("Node #{plugin_name} does not have an attached machine so cannot be created")
    end
    success
  end

  #---

  def download(remote_path, local_path, options = {})
    success = false

    if machine && machine.running?
      config      = Config.ensure(options)
      hook_config = Config.new({ :local_path => local_path, :remote_path => remote_path, :config => config })
      quiet       = config.get(:quiet, false)

      if extension_check(:download, hook_config)
        logger.info("Downloading from #{plugin_name}")

        info("Starting download of #{remote_path} to #{local_path}", { :i18n => false }) unless quiet
        yield(:config, hook_config) if block_given?

        active_machine = local? ? local_machine : machine

        success = active_machine.download(remote_path, local_path, config.export) do |name, received, total|
          info("#{name}: Sent #{received} of #{total}", { :i18n => false }) unless quiet
          yield(:progress, { :name => name, :received => received, :total => total })
        end

        if success && block_given?
          info("Successfully finished download of #{remote_path} to #{local_path}", { :i18n => false }) unless quiet
          process_success = yield(:process, hook_config)
          success         = process_success if process_success == false
        end

        if success
          extension(:download_success, hook_config)
        end
      end
    else
      logger.warn("Node #{plugin_name} does not have an attached machine or is not running so cannot download")
    end
    success
  end

  #---

  def upload(local_path, remote_path, options = {})
    success = false

    if machine && machine.running?
      config      = Config.ensure(options)
      hook_config = Config.new({ :local_path => local_path, :remote_path => remote_path, :config => config })
      quiet       = config.get(:quiet, false)

      if extension_check(:upload, hook_config)
        logger.info("Uploading to #{plugin_name}")

        info("Starting upload of #{local_path} to #{remote_path}", { :i18n => false }) unless quiet
        yield(:config, hook_config) if block_given?

        active_machine = local? ? local_machine : machine

        success = active_machine.upload(local_path, remote_path, config.export) do |name, sent, total|
          info("#{name}: Sent #{sent} of #{total}", { :i18n => false }) unless quiet
          yield(:progress, { :name => name, :sent => sent, :total => total })
        end

        if success && block_given?
          info("Successfully finished upload of #{local_path} to #{remote_path}", { :i18n => false }) unless quiet
          process_success = yield(:process, hook_config)
          success         = process_success if process_success == false
        end

        if success
          extension(:upload_success, hook_config)
        end
      end
    else
      logger.warn("Node #{plugin_name} does not have an attached machine or is not running so cannot upload")
    end
    success
  end

  #---

  def send_files(local_path, remote_path, files = nil, permission = '0644', options = {}, &code)
    local_path = File.expand_path(local_path)
    return false unless File.directory?(local_path)

    success = true

    send_file = lambda do |local_file, remote_file|
      send_success = upload(local_file, remote_file, options) do |op, upload_options|
        code.call(op, upload_options) if code
      end
      send_success = cli_check(:chmod, permission, remote_file) if send_success
      send_success
    end

    if files && files.is_a?(Array)
      files.flatten.each do |rel_file_name|
        local_file  = "#{local_path}/#{rel_file_name}"
        remote_file = "#{remote_path}/#{rel_file_name}"

        if File.exists?(local_file)
          send_success = send_file.call(local_file, remote_file)
          success      = false unless send_success
        end
      end
    else
      send_success = send_file.call(local_path, remote_path)
      success      = false unless send_success
    end
    success
  end

  #---

  def exec(options = {})
    default_error = Util::Shell::Result.new(:error, 255)
    results       = [ default_error ]

    if local? && local_machine || machine && machine.running?
      config = Config.ensure(options)

      if extension_check(:exec, { :config => config })
        logger.info("Executing node: #{plugin_name}")

        yield(:config, config) if block_given?

        if local? && local_machine
          active_machine = local_machine
        else
          active_machine = machine
        end

        if commands = config.get(:commands, nil)
          quiet = config.get(:quiet, false)

          begin
            test = active_machine.exec(commands, config.export) do |type, command, data|
              unless quiet
                unless local?
                  text_output = filter_output(type, data).rstrip

                  unless text_output.empty?
                    if type == :error
                      warn(text_output, { :i18n => false })
                    else
                      info(text_output, { :i18n => false })
                    end
                  end
                end
                yield(:progress, { :type => type, :command => command, :data => data }) if block_given?
              end
            end
            results = test if test

          rescue => error
            default_error.append_errors(error.message)
          end
        else
          default_error.append_errors("No execution command")
        end

        if results
          success = true
          results.each do |result|
            success = false if result.status != code.success
          end
          if success
            yield(:process, config) if block_given?
            extension(:exec_success, { :config => config, :results => results })
          end
        else
          default_error.append_errors("No execution results")
        end
      else
        default_error.append_errors("Execution prevented by exec hook")
      end
    else
      default_error.append_errors("No attached machine")

      logger.warn("Node #{plugin_name} does not have an attached machine or is not running so cannot execute commands")
    end
    results
  end

  #---

  def cli
    @cli_interface
  end

  #---

  def command(command, options = {})
    config         = Config.ensure(options)
    as_admin       = config.delete(:as_admin, false)
    remove_command = false

    unless command.is_a?(CORL::Plugin::Command)
      command        = CORL.command(Config.new({ :command => command }).import(config), :bash)
      remove_command = true
    end

    admin_command = ''
    if as_admin
      admin_command = config.delete(:admin_command, 'sudo -i')
      admin_command = extension_set(:admin_command, admin_command, config)
    else
      config.delete(:admin_command)
    end

    config[:commands] = [ "#{admin_command} #{command.to_s}".strip ]

    results = exec(config) do |op, data|
      yield(op, data) if block_given?
    end

    CORL.remove_plugin(command) if remove_command
    results.first
  end

  #---

  def action(provider, options = {})
    codes :network_load_error

    config = Config.ensure(options).defaults({
      :log_level    => Nucleon.log_level,
      :net_remote   => :edit,
      :net_provider => network.plugin_provider
    })

    logger.info("Executing remote action #{provider} with encoded arguments: #{config.export.inspect}")

    encoded_config = Util::CLI.encode(Util::Data.clean(config.export))
    action_config  = extended_config(:action, {
      :command => provider.to_s.gsub('_', ' '),
      :data    => { :encoded => encoded_config }
    })

    quiet    = config.get(:quiet, false)
    parallel = config.get(:parallel, true)

    command_base  = 'corl'
    command_base  = "NUCLEON_NO_PARALLEL=1 #{command_base}" unless parallel

    result = command(command_base, { :subcommand => action_config, :as_admin => true, :quiet => quiet }) do |op, data|
      yield(op, data) if block_given?
    end

    # Update local network configuration so we capture any updates
    if result.status == code.success && ! network.load({ :remote => config[:net_remote], :pull => true })
      result.status = code.network_load_error
    end
    result
  end

  #---

  def run
    @action_interface
  end

  #---

  def terminal(options = {})
    myself.status = code.unknown_status

    if machine && machine.running?
      config = Config.ensure(options)

      if extension_check(:terminal, { :config => config })
        logger.info("Launching terminal for node: #{plugin_name}")

        if local? && local_machine
          active_machine = local_machine
        else
          active_machine = machine
        end

        config[:private_keys] = private_key
        config[:port]         = ssh_port

        myself.status = active_machine.terminal(user, config.export)

        if status == code.success
          extension(:exec_success, { :config => config })
        end
      end
    else
      logger.warn("Node #{plugin_name} does not have an attached machine or is not running so cannot launch terminal")
    end
    status == code.success
  end

  #---

  def bootstrap(local_path, options = {})
    config      = Config.ensure(options)
    myself.status = code.unknown_status

    bootstrap_name    = 'bootstrap'
    bootstrap_path    = config.get(:bootstrap_path, File.join(CORL.lib_path, '..', bootstrap_name))
    bootstrap_glob    = config.get(:bootstrap_glob, '**/*.sh')
    bootstrap_init    = config.get(:bootstrap_init, 'bootstrap.sh')
    bootstrap_scripts = config.get_array(:bootstrap_scripts)

    user_home  = config[:home]
    auth_files = config.get_array(:auth_files)

    reboot       = config.get(:reboot, true)
    dev_build    = config.get(:dev_build, false)
    ruby_version = config.get(:ruby_version, nil)

    codes :local_path_not_found,
          :home_path_lookup_failure,
          :auth_upload_failure,
          :root_auth_copy_failure,
          :bootstrap_upload_failure,
          :bootstrap_exec_failure,
          :reload_failure

    if File.directory?(local_path)
      if user_home || user_home = home(config.get(:home_env_var, 'HOME'), config.get(:force, false))
        myself.status = code.success

        # Transmit authorisation / credential files
        package_files = [ '.fog', '.netrc', '.google-privatekey.p12', '.vimrc' ]
        auth_files.each do |file|
          package_files << file.gsub(local_path + '/', '')
        end
        send_success = send_files(local_path, user_home, package_files, '0600', { :quiet => true }) do |op, data|
          yield("send_#{op}".to_sym, data) if block_given?
          data
        end
        unless send_success
          myself.status = code.auth_upload_failure
        end

        if user.to_sym != config.get(:root_user, :root).to_sym
          auth_files     = package_files.collect { |path| "'#{path}'"}
          root_home_path = config.get(:root_home, '/root')

          result        = command("cp #{auth_files.join(' ')} #{root_home_path}", { :as_admin => true, :admin_command => 'sudo' })
          myself.status = code.root_auth_copy_failure unless result.status == code.success
        end

        # Send bootstrap package
        if status == code.success
          remote_bootstrap_path = File.join(user_home, bootstrap_name)

          cli.rm('-Rf', remote_bootstrap_path)
          send_success = send_files(bootstrap_path, remote_bootstrap_path, nil, '0700', { :quiet => true }) do |op, data|
            yield("send_#{op}".to_sym, data) if block_given?
            data
          end
          unless send_success
            myself.status = code.bootstrap_upload_failure
          end

          # Execute bootstrap process
          if status == code.success
            remote_script = File.join(remote_bootstrap_path, bootstrap_init)
            environment   = "HOSTNAME='#{hostname}' "
            environment  << "DEVELOPMENT_BUILD=1 " if dev_build
            environment  << "RUBY_RVM_VERSION='#{ruby_version}' " if ruby_version
            script_names  = bootstrap_scripts.empty? ? '' : bootstrap_scripts.join(' ')

            myself.bootstrap_script = remote_script

            result = command("#{environment} #{remote_script} #{script_names}", { :as_admin => true }) do |op, data|
              yield("exec_#{op}".to_sym, data) if block_given?
              data
            end

            if result.status == code.success
              # Reboot the machine
              if reboot && ! reload
                warn('corl.core.node.bootstrap.reload')
                myself.status = code.reload_failure
              end
            else
              warn('corl.core.node.bootstrap.status', { :script => remote_script, :status => result.status })
              myself.status = code.bootstrap_exec_failure
            end
          end
        end
      else
        myself.status = code.home_path_lookup_failure
      end
    else
      myself.status = code.local_path_not_found
    end
    status == code.success
  end

  #---

  def save(options = {})
    config = Config.ensure(options)

    # Record machine parameters
    if block_given?
      # Provider or external configuration preparation
      yield(config)
    else
      # Default configuration preparation
      id(true)
      public_ip(true)
      private_ip(true)
      state(true)

      machine_type(false)
      image(false)
    end

    network.save(config.import({
      :commit      => true,
      :allow_empty => true,
      :message     => config.get(:message, "Saving #{plugin_provider} node #{plugin_name}"),
      :remote      => config.get(:remote, :edit)
    }))
  end

  #---

  def start(options = {})
    success = true

    if machine
      config = Config.ensure(options)

      if extension_check(:start, { :config => config })
        logger.info("Starting node: #{plugin_name}")

        yield(:config, config) if block_given?
        success = machine.start(config.export)
        success = save(config) if success

        if success
          if config.get(:bootstrap, false) && bootstrap_script
            result = command("HOSTNAME='#{hostname}' #{bootstrap_script}", { :as_admin => true }) do |op, data|
              yield("bootstrap_#{op}".to_sym, data) if block_given?
              data
            end
            success = false unless result.status == code.success && reload
          end
        end

        if success && block_given?
          process_success = yield(:process, config)
          success         = process_success if process_success == false
        end

        if success
          extension(:start_success, { :config => config })
        end
      end
    else
      logger.warn("Node #{plugin_name} does not have an attached machine so cannot be started")
    end
    success
  end

  #---

  def reload(options = {})
    success = true

    if machine && machine.created?
      config = Config.ensure(options)

      if extension_check(:reload, { :config => config })
        logger.info("Reloading node: #{plugin_name}")

        yield(:config, config) if block_given?
        success = machine.reload(config.export)

        if success && block_given?
          process_success = yield(:process, config)
          success         = process_success if process_success == false
        end

        if success
          extension(:reload_success, { :config => config })
        end
      end
    else
      logger.warn("Node #{plugin_name} does not have an attached machine or is not created so cannot be reloaded")
    end
    success
  end

  #---

  def create_image(options = {})
    success = true

    if machine && machine.running?
      config = Config.ensure(options)

      if extension_check(:create_image, { :config => config })
        logger.info("Executing node: #{plugin_name}")

        yield(:config, config) if block_given?
        success = machine.create_image(config.export)
        success = save(config) if success

        if success && block_given?
          process_success = yield(:process, config)
          success         = process_success if process_success == false
        end

        if success
          extension(:create_image_success, { :config => config })
        end
      end
    else
      logger.warn("Node #{plugin_name} does not have an attached machine or is not running so cannot create an image")
    end
    success
  end

  #---

  def stop(options = {})
    success = true

    if machine && machine.running?
      config = Config.ensure(options)

      if extension_check(:stop, { :config => config })
        logger.info("Stopping node: #{plugin_name}")

        yield(:config, config) if block_given?
        success = machine.stop(config.export)

        myself.machine = nil

        override_settings = false
        override_settings = yield(:finalize, config) if success && block_given?

        if success && ! override_settings
          delete_setting(:id)
          delete_setting(:public_ip)
          delete_setting(:private_ip)
          delete_setting(:ssh_port)
          delete_setting(:build)

          myself[:state] = :stopped
        end
        success = save(config)

        if success && block_given?
          process_success = yield(:process, config)
          success         = process_success if process_success == false
        end

        if success
          extension(:stop_success, { :config => config })
        end
      end
    else
      logger.warn("Node #{plugin_name} does not have an attached machine or is not running so cannot be stopped")
    end
    success
  end

  #---

  def destroy(options = {})
    config  = Config.ensure(options)
    success = true

    if extension_check(:destroy, { :config => config })
      logger.info("Destroying node: #{plugin_name}")

      yield(:config, config) if block_given?

      if machine && machine.created?
        # Shut down machine
        success = machine.destroy(config.export)
        myself.machine = nil
      else
        logger.warn("Node #{plugin_name} does not have an attached machine or is not created so cannot be destroyed")
      end

      # Remove SSH keys
      if success && delete_keys
        # Remove node information
        network.delete_node(plugin_provider, plugin_name, false)

        network.save({
          :commit  => true,
          :remote  => config.get(:remote, :edit),
          :message => config.get(:message, "Destroying node #{plugin_name}"),
          :push    => true
        })
      end

      if success && block_given?
        process_success = yield(:process, config)
        success         = process_success if process_success == false
      end

      if success
        extension(:destroy_success, { :config => config })
        clear_cache
      end
    end
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
      options = { :name => data }
    when Hash
      options = data
    end

    if options.has_key?(:name)
      if matches = translate_reference(options[:name])
        options[:provider] = matches[:provider]
        options[:name]     = matches[:name]

        logger.debug("Translating node options: #{options.inspect}")
      end
    end
    options
  end

  #---

  def self.translate_reference(reference)
    # ex: rackspace:::web1.staging.example.com
    if reference && reference.match(/^\s*([a-zA-Z0-9_-]+):::([^\s]+)\s*$/)
      provider = $1
      name     = $2

      logger.debug("Translating node reference: #{provider}  #{name}")

      info = {
        :provider => provider,
        :name     => name
      }

      logger.debug("Project reference info: #{info.inspect}")
      return info
    end
    nil
  end

  #---

  def translate_reference(reference)
    myself.class.translate_reference(reference)
  end

  #-----------------------------------------------------------------------------
  # CLI utilities

  def cli_capture(cli_command, *args)
    result = exec({ :commands => [ [ cli_command, args ].flatten.join(' ') ], :quiet => true })
    result = result.first

    if result.status == code.success && ! result.output.empty?
      result.output
    else
      nil
    end
  end

  #---

  def cli_check(cli_command, *args)
    result = cli.send(cli_command, args)
    result.status == code.success ? true : false
  end

  #---

  def filter_output(type, data)
    if type == :output
      # Hide redundant Facter output
      if data =~ /^Already evaluated [a-z]+ at [^,]+, reevaluating anyways$/
        data = ''
      end
    elsif type == :error
      # Hide Rubinius SAFE warning
      if data == 'WARNING: $SAFE is not supported on Rubinius.'
        data = ''
      end
    end
    data
  end

  #-----------------------------------------------------------------------------
  # Machine type utilities

  def machine_type_id(machine_type)
    machine_type.id
  end

  #---

  def render_machine_type(machine_type)
    ''
  end

  #-----------------------------------------------------------------------------
  # Image utilities

  def image_id(image)
    image.id
  end

  #---

  def render_image(image)
    ''
  end

  #---

  def image_search_text(image)
    image.to_s
  end
end
end
end

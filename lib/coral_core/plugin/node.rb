
module Coral
module Plugin
class Node < Base
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
   
  def normalize
    super
    
    @cli_interface = Util::Liquid.new do |method, args|
      result = exec({ :commands => [ [ method, args ].flatten.join(' ') ] }).first
      
      ui_group!(hostname) do          
        ui.alert(result.errors) unless result.errors.empty?
      end
      result
    end
    
    @action_interface = Util::Liquid.new do |method, args|
      action(method, *args)
    end
  end
  
  #---
  
  def localize
    @local_context = true
  end
       
  #-----------------------------------------------------------------------------
  # Checks
  
  def local?
    @local_context ? true : false
  end
  
  #---
  
  def usable_image?(image)
    true
  end   
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def network
    return plugin_parent
  end
 
  def network=network
    self.plugin_parent = network
  end
  
  #---
  
  def setting(property, default = nil, format = false)
    return network.node_setting(plugin_provider, name, property, default, format)
  end
  
  def search(property, default = nil, format = false)
    return network.search_node(plugin_provider, name, property, default, format)
  end
  
  def set_setting(property, value = nil)
    network.set_node_setting(plugin_provider, name, property, value)
    return self
  end
  
  def delete_setting(property)
    network.delete_node_setting(plugin_provider, name, property)
    return self
  end
  
  #---
 
  def [](name, default = nil, format = false)
    search(name, default, format)
  end
  
  #---
  
  def []=(name, value)
    set_setting(name, value)
  end
   
  #-----------------------------------------------------------------------------
  
  def groups
    search(:groups, [], :array)
  end
  
  #-----------------------------------------------------------------------------
  
  def machine
    @machine
  end
  
  #---
  
  def machine=machine
    @machine = machine  
  end
  
  #---
 
  def create_machine(provider, options = {})
    if provider.is_a?(String) || provider.is_a?(Symbol)
      self.machine = Coral.plugin_load(:machine, provider, options)
    end
    self
  end
  
  #---
  
  def id # Must be set at machine level
    return machine.name if machine
    nil
  end
 
  #---
  
  def public_ip # Must be set at machine level
    return machine.public_ip if machine
    nil
  end

  #---
  
  def private_ip # Must be set at machine level
    return machine.private_ip if machine
    nil
  end

  #---
 
  def hostname # Must be set at machine level
    return machine.hostname if machine
    ''
  end
 
  #---
 
  def state # Must be set at machine level
    return machine.state if machine
    nil
  end
  
  #---
  
  def private_key=private_key
    self[:private_key] = private_key
  end
  
  def private_key
    config_key = self[:private_key]
    return File.expand_path(config_key) if config_key
    nil
  end
  
  #---
  
  def public_key=public_key
    self[:public_key] = public_key
  end
  
  def public_key
    config_key = self[:private_key]
    return File.expand_path(config_key) if config_key
  end
  
  #---
  
  def home(env_var = 'HOME', reset = false)
    if reset || ! self[:user_home]
      self[:user_home] = cli_capture(:echo, '$' + env_var.to_s.gsub('$', '')) if machine
    end
    self[:user_home]
  end
  
  #---
    
  def machine_types # Must be set at machine level (queried)
    machine.machine_types if machine
  end
    
  def machine_type=machine_type
    self[:machine_type] = machine_type
  end
  
  def machine_type
    machine_type = self[:machine_type]
    
    if machine_type.nil? && machine
      if types = machine_types
        unless types.empty?
          machine_type      = machine_type_id(types.first)
          self.machine_type = machine_type
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
    self[:image] = image
  end
  
  def image
    self[:image]
  end
   
  #-----------------------------------------------------------------------------
  # Machine operations
  
  def create(options = {})
    success = true
    
    if machine
      config = Config.ensure(options)
      
      if extension_check(:create, { :config => config })
        logger.info("Creating node: #{name}")
      
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
      logger.warn("Node #{name} does not have an attached machine so cannot be created")
    end
    success
  end
  
  #---
  
  def download(remote_path, local_path, options = {})
    success = false
    
    if machine && machine.running?
      config      = Config.ensure(options)
      hook_config = Config.new({ :local_path => local_path, :remote_path => remote_path, :config => config })
      
      if extension_check(:download, hook_config)
        logger.info("Downloading from #{name}")
      
        yield(:config, hook_config) if block_given?
        
        success = machine.download(remote_path, local_path, config.export) do |name, received, total|
          yield(:progress, { :name => name, :received => received, :total => total })
        end
        
        if success && block_given?
          process_success = yield(:process, hook_config)
          success         = process_success if process_success == false        
        end
        
        if success
          extension(:download_success, hook_config)
        end
      end
    else
      logger.warn("Node #{name} does not have an attached machine or is not running so cannot download")
    end
    success
  end
  
  #---
  
  def upload(local_path, remote_path, options = {})
    success = false
    
    if machine && machine.running?
      config      = Config.ensure(options)
      hook_config = Config.new({ :local_path => local_path, :remote_path => remote_path, :config => config })
      
      if extension_check(:upload, hook_config)
        logger.info("Uploading to #{name}")
      
        yield(:config, hook_config) if block_given?
        
        success = machine.upload(local_path, remote_path, config.export) do |name, sent, total|
          yield(:progress, { :name => name, :sent => sent, :total => total })  
        end
        
        if success && block_given?
          process_success = yield(:process, hook_config)
          success         = process_success if process_success == false        
        end
        
        if success
          extension(:upload_success, hook_config)
        end
      end
    else
      logger.warn("Node #{name} does not have an attached machine or is not running so cannot upload")
    end
    success
  end
  
  #---
  
  def send_files(local_path, remote_path, files = nil, permission = '0644', &code)
    local_path = File.expand_path(local_path)
    return false unless File.directory?(local_path)
    
    success = true
    
    send_file = lambda do |local_file, remote_file|
      send_success = upload(local_file, remote_file) do |op, options|
        code.call(op, options) if code
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
    results = nil
    
    if machine && machine.running?
      config = Config.ensure(options)
      
      if extension_check(:exec, { :config => config })
        logger.info("Executing node: #{name}")
      
        yield(:config, config) if block_given?
        
        if commands = config.get(:commands, nil)
          results = machine.exec(commands, config.export) do |type, command, data|
            yield(:progress, { :type => type, :command => command, :data => data })    
          end
        end
        
        success  = true
        results.each do |result|
          success = false if result.status != Coral.code.success  
        end
        if success
          yield(:process, config) if block_given?
          extension(:exec_success, { :config => config, :results => results }) 
        end
      end
    else
      logger.warn("Node #{name} does not have an attached machine or is not running so cannot execute commands")
    end
    results 
  end
  
  #---
  
  def cli
    @cli_interface
  end
  
  #---
  
  def command(command, options = {})
    unless command.is_a?(Coral::Plugin::Command)
      command = Coral.command(Config.new({ :command => command }).import(options), :shell)
    end
    exec({ :commands => [ command.to_s ] }) do |op, results|
      yield(op, results) if block_given?  
    end.first
  end
  
  #---
  
  def action(provider, options = {})
    config         = Config.ensure(options)
    encoded_config = Util::CLI.encode(config.export)
    
    logger.info("Executing remote action #{provider} with encoded arguments: #{config.export.inspect}")
    
    action_config = extended_config(:action, {
      :command => provider, 
      :data    => { :encoded => encoded_config }
    })
    command(:coral, { :subcommand => action_config }) do |op, results|
      yield(op, results) if block_given?  
    end  
  end
  
  #---
  
  def run
    @action_interface
  end
  
  #---
   
  def bootstrap(local_path, options = {})
    config      = Config.ensure(options)
    self.status = code.unknown_status
    
    bootstrap_name = 'bootstrap'    
    bootstrap_path = config.get(:bootstrap_path, File.join(Plugin.core.full_gem_path, bootstrap_name))
    bootstrap_glob = config.get(:bootstrap_glob, '**/*.sh')
    bootstrap_init = config.get(:bootstrap_init, 'bootstrap.sh')
    
    user_home  = config[:home]
    auth_files = config.get_array(:auth_files)
    
    codes :local_path_not_found,
          :home_path_lookup_failure,
          :auth_upload_failure,
          :bootstrap_upload_failure,
          :bootstrap_exec_failure
    
    if File.directory?(local_path)      
      if user_home || user_home = home(config.get(:home_env_var, 'HOME'), config.get(:force, false))
        self.status = code.success
        
        # Transmit authorisation / credential files
        package_files = [ '.fog', '.netrc', '.google-privatekey.p12' ]
        auth_files.each do |file|
          package_files = file.gsub(local_path + '/', '')
        end
        send_success = send_files(local_path, user_home, package_files, '0600') do |op, results|
          yield("send_#{op}".to_sym, results) if block_given?
        end
        unless send_success
          self.status = code.auth_upload_failure
        end
    
        # Send bootstrap package
        if status == code.success
          remote_bootstrap_path = File.join(user_home, bootstrap_name)
          
          cli.rm('-Rf', remote_bootstrap_path)
          send_success = send_files(bootstrap_path, remote_bootstrap_path, nil, '0700') do |op, results|
            yield("send_#{op}".to_sym, results) if block_given?
          end
          unless send_success
            self.status = code.bootstrap_upload_failure
          end
          
          # Execute bootstrap process
          if status == code.success
            remote_script = File.join(remote_bootstrap_path, bootstrap_init)                  
            result = command(remote_script) do |op, results|
              yield("exec_#{op}".to_sym, results) if block_given?  
            end
            
            if result.status != code.success
              self.status = code.bootstrap_exec_failure  
            end
          end
        end
      else
        self.status = code.home_path_lookup_failure            
      end
    else
      self.status = code.local_path_not_found
    end
    status == code.success
  end
  
  #---
  
  def save(options = {})
    config = Config.ensure(options)
    
    # Record machine parameters
    self[:id]         = id
    self[:public_ip]  = public_ip
    self[:private_ip] = private_ip
    self[:hostname]   = hostname
    self[:state]      = state
    
    # Provider or external configuration preparation
    yield(config) if block_given?
    
    remote = config.get(:remote, :edit)
    
    network.save(config.import({ 
      :commit      => true,
      :allow_empty => true,
      :message     => config.get(:message, "Saving #{plugin_provider} node #{name}"),
      :remote      => remote 
    }))    
  end
  
  #---
   
  def start(options = {})
    success = true
    
    if machine
      config = Config.ensure(options)
      
      if extension_check(:start, { :config => config })
        logger.info("Starting node: #{name}")
      
        yield(:config, config) if block_given?      
        success = machine.start(config.export)
        
        if success && block_given?
          process_success = yield(:process, config)
          success         = process_success if process_success == false        
        end
        
        if success
          extension(:start_success, { :config => config })
        end
      end
    else
      logger.warn("Node #{name} does not have an attached machine so cannot be started")
    end
    success
  end
  
  #---
    
  def reload(options = {})
    success = true
    
    if machine && machine.created?
      config = Config.ensure(options)
      
      if extension_check(:reload, { :config => config })
        logger.info("Reloading node: #{name}")
      
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
      logger.warn("Node #{name} does not have an attached machine or is not created so cannot be reloaded")
    end
    success
  end
  
  #---
  
  def create_image(options = {})
    success = true
    
    if machine && machine.running?
      config = Config.ensure(options)
      
      if extension_check(:create_image, { :config => config })
        logger.info("Executing node: #{name}")
      
        yield(:config, config) if block_given?      
        success = machine.create_image(config.export)
        
        if success && block_given?
          process_success = yield(:process, config)
          success         = process_success if process_success == false        
        end
        
        if success
          extension(:create_image_success, { :config => config })
        end
      end
    else
      logger.warn("Node #{name} does not have an attached machine or is not running so cannot create an image")
    end
    success   
  end
   
  #---
    
  def stop(options = {})
    success = true
    
    if machine && machine.running?
      config = Config.ensure(options)
      
      if extension_check(:stop, { :config => config })
        logger.info("Stopping node: #{name}")
      
        yield(:config, config) if block_given?      
        success = machine.stop(config.export)
        
        if success && block_given?
          process_success = yield(:process, config)
          success         = process_success if process_success == false        
        end
        
        if success
          extension(:stop_success, { :config => config })
        end
      end
    else
      logger.warn("Node #{name} does not have an attached machine or is not running so cannot be stopped")
    end
    success
  end

  #---

  def destroy(options = {})    
    success = true
    
    if machine && machine.created?
      config = Config.ensure(options)
      
      run = false

      if config[:force]
        run = true
      else
        choice = nil
        begin
          choice = ui.ask("Are you sure you want to permanently destroy (Y|N): #{name}?")
          run    = choice.upcase == "Y"
          
        rescue Errors::UIExpectsTTY
          run = false
        end        
      end

      if run
        if extension_check(:destroy, { :config => config })
          logger.info("Destroying node: #{name}")
      
          yield(:config, config) if block_given?      
          success = machine.destroy(config.export)
        
          if success && block_given?
            process_success = yield(:process, config)
            success         = process_success if process_success == false        
          end
        
          if success
            extension(:destroy_success, { :config => config })
          end
        end
      else
        logger.warn("Node #{name} does not have an attached machine or is not created so cannot be destroyed")
      end
    else
      logger.info("Node #{name} not destroyed due to user cancellation")  
    end
    success    
  end

  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.build_info(type, data)  
    data = data.split(/\s*,\s*/) if data.is_a?(String)
    super(type, data)
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
    self.class.translate_reference(reference)
  end
  
  #-----------------------------------------------------------------------------
  # CLI utilities
  
  def cli_capture(cli_command, *args)
    dbg(cli_command, 'CLI command')
    dbg(args, 'arguments')
    result = cli.send(cli_command, args)
             
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

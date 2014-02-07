
module Coral
module Plugin
class Node < Base
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
   
  def normalize
    super
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
    setting(name, default, format)
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
    set(:private_key, private_key)
  end
  
  def private_key
    return File.expand_path(get(:private_key)) if get(:private_key, false)
    nil
  end
  
  #---
  
  def public_key=public_key
    set(:public_key, public_key)
  end
  
  def public_key
    return File.expand_path(get(:public_key)) if get(:public_key, false)
  end
  
  #---
    
  def machine_types # Must be set at machine level (queried)
    machine.machine_types if machine
  end
    
  def machine_type=machine_type
    set(:machine_type, machine_type)
  end
  
  def machine_type
    machine_type = get(:machine_type, nil)
    
    if machine_type.nil? && machine
      if types = machine_types
        machine_type      = machine_type_id(types.first)
        self.machine_type = machine_type
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
    set(:image, image)
  end
  
  def image
    get(:image, nil)
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

  #---
  
  def download(remote_path, local_path, options = {})
    success = false
    
    if machine && machine.running?
      config = Config.ensure(options)
      
      if extension_check(:download, { :local_path => local_path, :remote_path => remote_path, :config => config })
        logger.info("Downloading from #{name}")
      
        yield(:config, config) if block_given?
        
        success = machine.download(remote_path, local_path, config.export)
        
        if success && block_given?
          process_success = yield(:process, config)
          success         = process_success if process_success == false        
        end
        
        if success
          extension(:download_success, { :local_path => local_path, :remote_path => remote_path, :config => config })
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
      config = Config.ensure(options)
      
      if extension_check(:upload, { :local_path => local_path, :remote_path => remote_path, :config => config })
        logger.info("Uploading to #{name}")
      
        yield(:config, config) if block_given?
        
        success = machine.upload(local_path, remote_path, config.export)
        
        if success && block_given?
          process_success = yield(:process, config)
          success         = process_success if process_success == false        
        end
        
        if success
          extension(:upload_success, { :local_path => local_path, :remote_path => remote_path, :config => config })
        end
      end
    else
      logger.warn("Node #{name} does not have an attached machine or is not running so cannot upload")
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
        
        commands = config.get(:commands, nil)
        results  = machine.exec(commands, config.export) if commands
        success  = true
        
        results.each do |result|
          success = false if result[:status] != Coral.code.success  
        end
        if success
          yield(:process, config) if block_given?
          extension(:exec_success, { :config => config }) 
        end
      end
    else
      logger.warn("Node #{name} does not have an attached machine or is not running so cannot execute commands")
    end
    results 
  end
  
  #---
  
  def command(command, options = {})
    unless command.is_a?(Coral::Plugin::Command)
      command = Coral.command(Config.new({ :command => command }).import(options), :shell)
    end
    exec({ :commands => [ command.to_s ] }).first
  end
  
  #---
  
  def action(provider, options = {})
    require 'base64'
    
    config         = Config.ensure(options)
    encoded_config = Base64.encode64(Util::Data.to_json(config.export, false))
    decoded_config = symbol_map(Util::Data.parse_json(Base64.decode64(encoded_config)))
    
    dbg(config.export, 'original config')
    dbg(encoded_config, 'encoded config')
    dbg(decoded_config, 'decoded config')
    
    action_config = extended_config(:action, {
      :command => provider, 
      :data    => { :encoded => Base64.encode64(Util::Data.to_json(config.export, false)) }
    })
    command(:coral, { :subcommand => action_config })  
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
  
  #---
  
  def machine_type_id(machine_type)
    machine_type.id
  end
  
  #---
  
  def render_machine_type(machine_type)
    ''  
  end
  
  #---
  
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

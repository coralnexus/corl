
module CORL
module Machine
class Vagrant < CORL.plugin_class(:machine)
  
  @@lock = Mutex.new
    
  #-----------------------------------------------------------------------------
  # Checks
  
  def created?
    server && state != :not_created
  end
  
  #---
  
  def running?
    server && state == :running
  end
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def set_command
    @command = nil
    
    begin
      # Ensure we are running within Vagrant from the corl base command
      require 'vagrant'
      
      logger.info("Setting up Vagrant for machine")
      @command = CORL::Vagrant.command 
      
    rescue LoadError
    end
  end
  protected :set_command
  
  #---
  
  def command
    set_command unless @command
    @command
  end
  
  #---
  
  def env
    return command.env if command
    nil
  end
  
  #---
  
  def server=id
    @server = nil
    
    if id.is_a?(String)
      @server = new_machine(id)
    elsif ! id.nil?
      @server = id
    end
  end
  
  def server
    command
    load unless @server
    @server
  end
  
  #---
  
  def state
    return server.state.id if server
    :not_loaded
  end
  
  #---
    
  def machine_types
    [ :virtualbox, :vmware_fusion, :hyperv ]
  end
        
  #-----------------------------------------------------------------------------
  # Management

  def load
    super do
      myself.server = plugin_name if command && plugin_name
      ! plugin_name && @server.nil? ? false : true
    end    
  end
  
  #---
  
  def create(options = {})
    super do |config|
      start_machine(config)
    end
  end
  
  #---
  
  def download(remote_path, local_path, options = {})
    super do |config, success|
      begin
        server.communicate.tap do |comm|
          comm.download(remote_path, local_path)  
        end
        success = true
          
      rescue Exception => error
        ui.error(error.message)
        success = false
      end
      success
    end  
  end
  
  #---
  
  def upload(local_path, remote_path, options = {})
    super do |config, success|
      begin
        server.communicate.tap do |comm|
          comm.upload(local_path, remote_path)  
        end
        success = true
          
      rescue Exception => error
        ui.error(error.message)
        success = false
      end
      success
    end  
  end
  
  #---
  
  def exec(commands, options = {})
    super do |config, results|
      codes :vagrant_exec_failed
        
      begin
        server.communicate.tap do |comm|            
          commands.each do |command|
            as_admin = command.match(/^sudo\s+/) ? true : false
            result   = Util::Shell::Result.new(command.gsub(/^sudo\s+/, '').strip)
            
            result.status = comm.execute(result.command, { :sudo => as_admin }) do |type, data|
              case type
              when :stdout
                result.append_output(data)
                yield(:output, result.command, data) if block_given?      
              when :stderr
                result.append_errors(data)
                yield(:error, result.command, data) if block_given?  
              end  
            end
            results << result
          end
        end
          
      rescue Exception => error
        ui.error(error.message)
        results << Util::Shell::Result.new(command, code.vagrant_exec_failed)
      end      
      results
    end    
  end
  
  #---
  
  def terminal(user, options = {})
    super do |config|
      run(:ssh, { :ssh_opts => config.export }) 
    end
  end
  
  #---
  
  def reload(options = {})
    super do |config|
      run(:reload, config)
    end
  end

  #---
 
  def create_image(options = {})
    super do |config|
      stop = config.delete(:stop, false)
      
      # TODO: Decide how to handle versions??  
      # Timestamps stink since these things are huge (>600MB)
      box_name = sprintf("%s", node.id).gsub(/\s+/, '-')
      box_path = File.join(node.network.directory, 'boxes', "#{box_name}.box")
      box_url  = "file://#{box_path}"
      FileUtils.mkdir_p(File.dirname(box_path))
      FileUtils.rm_f(box_path)
      
      begin
        success = run(:package, config.defaults({ 'package.output' => box_path }), false)
      
        node.set_cache_setting(:box, box_name)
        node.set_cache_setting(:box_url, box_url)
        
        if success    
          env.action_runner.run(::Vagrant::Action.action_box_add, {
            :box_name  => box_name,
            :box_url   => box_url,          
            :box_clean => false,
            :box_force => true,
            :ui        => ::Vagrant::UI::Prefixed.new(env.ui, "box")
          })
          load
        end
        
      rescue Exception => error
        ui.error(error.message)
        success = false
      end
      
      success = run(:up, config) if success && ! stop
      success
    end
  end
  
  #---
  
  def stop(options = {})
    super do |config|
      create_image(config.import({ :stop => true }))
    end
  end
  
  #---
  
  def start(options = {})
    super do |config|
      start_machine(config)  
    end
  end
 
  #---

  def destroy(options = {})
    super do |config|
      # We should handle prompting internally to keep it consistent
      success = run(:destroy, config.defaults({ :force_confirm_destroy => true }))
      
      if success
        box_name = sprintf("%s", node.id).gsub(/\s+/, '-')
        found    = false
        
        # TODO: Figure out box versions.
        
        env.boxes.all.each do |info|
          registered_box_name     = info[0]
          registered_box_version  = info[1]
          registered_box_provider = info[2]
          
          if box_name == registered_box_name
            found = true
            break
          end
        end        
        
        if found
          env.action_runner.run(::Vagrant::Action.action_box_remove, {
            :box_name     => box_name,
            :box_provider => node.machine_type
          })
        end
      end
      success
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def refresh_config
    if env
      @@lock.synchronize do
        begin
          CORL::Vagrant::Config.network = node.network
          env.vagrantfile.reload
        ensure
          CORL::Vagrant::Config.network = nil
        end
      end
    end
  end
  protected :refresh_config
  
  #---
  
  def new_machine(id)
    server = nil
    if command && ! id.empty?
      if env.vagrantfile.machine_names.include?(id.to_sym)
        refresh_config
        server = command.vm_machine(id.to_sym, node.machine_type, true)
      end
    end
    server
  end
  protected :new_machine
  
  #---
  
  def start_machine(options)
    success = false
    
    if server
      load
      success = run(:up, options)
        
      # Make sure provisioner changes (key changes) are accounted for
      # TODO: Is there a better way?
      load if success
    end
    success  
  end
  protected :start_machine
  
  #---
  
  def run(action, options = {}, symbolize_keys = true)
    config = Config.ensure(options)
    
    if server
      logger.debug("Running Vagrant action #{action} on machine #{node.id}")
    
      success = true
      begin
        params = config.export
        params = string_map(params) unless symbolize_keys
        
        server.send(:action, action.to_sym, params)
        
      rescue Exception => error
        ui.error(error)
        ui.error(Util::Data.to_yaml(error.backtrace))
        success = false
      end      
    end
    success
  end
  protected :run
end
end
end
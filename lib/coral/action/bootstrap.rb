
module Coral
module Action
class Bootstrap < Plugin::Action

  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :network_failure
      
      register :auth_files, :array, [] do |values|
        success = true
        values.each do |value|
          unless File.exists?(value)
            warn('coral.actions.bootstrap.errors.auth_files', { :value => value })
            success = false
          end
        end
        success
      end
      register :home_env_var, :str, 'HOME'
      register :home, :str, nil    
      register :bootstrap_path, :str, File.join(Plugin.core.full_gem_path, 'bootstrap') do |value|
        unless File.directory?(value)
          warn('coral.actions.bootstrap.errors.bootstrap_path', { :value => value })
          next false
        end
        true
      end
      register :bootstrap_glob, :str, '**/*.sh'
      register :bootstrap_init, :str, 'bootstrap.sh'
      
      register :bootstrap_nodes, :array, nil do |values|
        node_plugins = Plugin.loaded_plugins(:node)
        success      = true
        
        values.each do |value|
          if info = Plugin::Node.translate_reference(value)
            if ! node_plugins.keys.include?(info[:provider].to_sym) || info[:name].empty?
              warn('coral.actions.bootstrap.errors.bootstrap_nodes', { :value => value, :provider => info[:provider],  :name => info[:name] })
              success = false
            end
          end
        end
        success
      end
    end
  end
  
  #---
  
  def ignore
    [ :nodes ]
  end
  
  def arguments
    [ :bootstrap_nodes ]
  end

  #-----------------------------------------------------------------------------
  # Operations
    
  def execute
    settings[:nodes] = [] # Just in case it made it through (special case)
    
    super do |local_node, network|
      info('coral.core.actions.bootstrap.start')
      
      if network
        batch_success = network.batch(settings[:bootstrap_nodes], settings[:node_provider], settings[:parallel]) do |node|
          home_path = extension_set(:home_path, ( ENV['USER'] == 'root' ? '/root' : ENV['HOME'] ), { :node => node }) 
          
          success = node.bootstrap(home_path, extended_config(:bootstrap, {
            :auth_files     => settings[:auth_files],
            :home           => settings[:home],
            :home_env_var   => settings[:home_env_var],
            :bootstrap_path => settings[:bootstrap_path],
            :bootstrap_glob => settings[:bootstrap_glob],
            :bootstrap_init => settings[:bootstrap_init]
          })) do |op, data|
            case op
            when :send_config # Modify upload configurations
              render("Starting upload of #{data[:local_path]} to #{data[:remote_path]}")  
            when :send_progress # Report progress of uploading files
              render("#{data[:name]}: Sent #{data[:sent]} of #{data[:total]}")  
            when :send_process # Process final result
              render("Successfully finished upload of #{data[:local_path]} to #{data[:remote_path]}")
            when :exec_config # Modify bootstrap execution configurations
              render("Starting execution of bootstrap package")  
            when :exec_progress # Report progress of bootstrap execution
              if data[:type] == :error
                alert(data[:data])
              else
                render(data[:data])
              end  
            when :exec_process # Process final result
              render("Successfully finished execution of bootstrap package")     
            end
            data  
          end
          render('We are all good!') if success
          success  
        end
        self.status = code.batch_error unless batch_success
      else
        alert("Failed to load network")
        self.status = code.network_failure
      end
    end
  end
end
end
end

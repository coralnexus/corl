
module Coral
module Action
class Bootstrap < Plugin::Action

  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :network_failure,
            :node_load_failure
      #---
      
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
      
      register :node_name, :str, nil      
      config[:node_provider].default = nil
    end
  end
  
  #---
  
  def ignore
    node_ignore - [ :node_provider ]
  end
  
  def arguments
    [ :node_provider, :node_name ]
  end

  #-----------------------------------------------------------------------------
  # Operations
    
  def execute
    super do |node, network|
      info('coral.core.actions.bootstrap.start')
      
      if network
        if bootstrap_node = network.node(settings[:node_provider], settings[:node_name])
          ui_group!(bootstrap_node.hostname) do
            home_path = extension_set(:home_path, ( ENV['USER'] == 'root' ? '/root' : ENV['HOME'] ), { :node => bootstrap_node }) 
          
            success = bootstrap_node.bootstrap(home_path, extended_config(:bootstrap, {
              :auth_files     => settings[:auth_files],
              :home           => settings[:home],
              :home_env_var   => settings[:home_env_var],
              :bootstrap_path => settings[:bootstrap_path],
              :bootstrap_glob => settings[:bootstrap_glob],
              :bootstrap_init => settings[:bootstrap_init]
            })) do |op, results|
              case op
              when :send_config # Modify upload configurations
                render("Starting upload of #{results[:local_path]} to #{results[:remote_path]}")  
              when :send_progress # Report progress of uploading files
                render("#{results[:name]}: Sent #{results[:sent]} of #{results[:total]}")  
              when :send_process # Process final result
                render("Successfully finished upload of #{results[:local_path]} to #{results[:remote_path]}")
              when :exec_config # Modify bootstrap execution configurations
                render("Starting execution of bootstrap package")  
              when :exec_progress # Report progress of bootstrap execution
                if results[:type] == :error
                  alert(results[:data], { :prefix => false })
                else
                  render(results[:data], { :prefix => false })
                end  
              when :exec_process # Process final result
                render("Successfully finished execution of bootstrap package")     
              end
              results  
            end
            self.status = bootstrap_node.status unless success
            render('We are all good!') if success
          end
        else
          alert("Failed to load bootstrap node: #{settings[:node_provider]} #{settings[:node_name]}")
          self.status = code.node_load_failure    
        end
      else
        alert("Failed to load network")
        self.status = code.network_failure
      end
    end
  end
end
end
end

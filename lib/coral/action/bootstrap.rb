
module Coral
module Action
class Bootstrap < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action settings
  
  def configure
    super do
      @bootstrap_name = 'bootstrap' # Bootstrap directory relative to top level gem path
            
      codes :network_failure,
            :bootstrap_path_failure,
            :package_failure,
            :home_lookup_failure,
            :extract_failure,
            :bootstrap_exec_failure
      #---
          
      register :bootstrap, :str, File.join(Plugin.core.full_gem_path, @bootstrap_name) do |value|
        unless File.directory?(value)
          warn('coral.actions.bootstrap.errors.bootstrap', { :value => value })
          next false
        end
        true
      end
      register :gateway, :str, 'bootstrap.sh'
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
  # Action operations
    
  def execute
    super do |node, network|
      info('coral.core.actions.bootstrap.start')
      
      if network
        if bootstrap_node = network.node(settings[:node_provider], settings[:node_name])
          bootstrap_path = settings[:bootstrap]
          
          if File.directory?(bootstrap_path)
            # Create initiation package            
            home_path   = ( ENV['USER'] == 'root' ? '/root' : ENV['HOME'] )     
            package     = initiation_package(home_path, settings[:auth_files])
            self.status = code.package_failure if package.nil?
            
            # Get remote user home directory
            if status = code.success
              if settings[:home]
                remote_home = settings[:home] 
              else
                remote_home = bootstrap_node.home(settings[:home_env_var])
                self.status = code.home_lookup_failure if remote_home.nil?
              end
            end
            
            # Clean remote bootstrap (if exists)
            if status = code.success
              remote_bootstrap = File.join(remote_home, @bootstrap_name)
              bootstrap_node.cli.rm('-Rf', remote_bootstrap)
            end
            
            if status = code.success
              # Transmit initiation package
              if bootstrap_node.run.extract({ :path => remote_home, :encoded => package.encode }).status == code.success
                # Execute bootstrap scripts
                gateway_script = settings[:gateway]
                remote_script  = File.join(remote_bootstrap, gateway_script)                  
                result         = bootstrap_node.command("HOSTNAME=#{bootstrap_node.hostname} #{remote_script}")
                
                ui_group!(bootstrap_node.hostname) do  
                  render(result.output)
                  alert(result.errors)
                end
                  
                if result.status == code.success
                  success('coral.core.actions.bootstrap.success')
                else
                  warn('coral.core.actions.bootstrap.error', { :status => result.status })
                  self.status = code.bootstrap_exec_failure
                end  
              else
                self.status = code.extract_failure
              end               
            end           
          else
            self.status = code.bootstrap_path_failure
          end
        end
      else
        self.status = code.network_failure
      end
    end
  end
  
  #---
  
  def initiation_package(home_path, auth_files = [])
    # Create initiation package            
    package = nil
    
    if File.directory?(home_path)
      package = Util::Package.new
                
      # Pluggable authentication files
      package.add_file("#{home_path}/.fog", '.fog')
      package.add_file("#{home_path}/.netrc", '.netrc')
            
      # Special cases :-(   
      package.add_file("#{home_path}/.google-privatekey.p12", '.google-privatekey.p12')
            
      # Extra credential files given
      auth_files.each do |file|
        package.add_file(file, file.gsub(home_path + '/', ''))
      end
            
      # Add bootstrap scripts
      package.add_files(bootstrap_path, '**/*.sh', 'bootstrap', 0700)
    end
    package
  end
end
end
end

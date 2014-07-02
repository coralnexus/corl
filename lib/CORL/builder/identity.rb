
module CORL
module Builder
class Identity < CORL.plugin_class(:CORL, :builder)
   
  #-----------------------------------------------------------------------------
  # Identity plugin interface
 
  def normalize(reload)
    super do
      @identities = {}
    end
  end

  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def build_directory
    File.join(network.directory, 'config', 'identities')
  end
  
  #---
  
  def identities
    @identities
  end
  
  def set_identity(name, directory)
    @identities[name] = directory
  end
 
  #-----------------------------------------------------------------------------
  # Identity interface operations
  
  def build_provider(name, project_reference, environment)
    provider_id = id(name)
    directory   = File.join(internal_path(build_directory), provider_id.to_s)
    success     = true
      
    ui.info("Building identity #{blue(name)} at #{purple(project_reference)} into #{green(directory)}")
      
    full_directory = File.join(network.directory, directory)
      
    unless identities.has_key?(provider_id)
      project = build_config.manage(:project, extended_config(:identity, {
        :directory     => full_directory,
        :url           => project_reference,
        :create        => File.directory?(full_directory) ? false : true,
        :pull          => true,
        :internal_ip   => CORL.public_ip, # Needed for seeding Vagrant VMs
        :manage_ignore => false
      }))
      unless project
        ui.warn("Identity #{cyan(name)} failed to initialize")
        success = false
      end
           
      if success
        # Make thid project private.
        FileUtils.chmod_R('go-wrx', full_directory)
          
        set_identity(provider_id, full_directory)
        build_config.set_location(plugin_provider, name, directory)
      end
    end
    ui.success("Build of identity #{blue(name)} finished") if success
    success
  end
end
end
end

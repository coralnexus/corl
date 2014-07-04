
module CORL
module Builder
class Package < CORL.plugin_class(:CORL, :builder)
  
  #-----------------------------------------------------------------------------
  # Package plugin interface
 
  def normalize(reload)
    super do
      @packages = {}
    end
  end

  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def build_directory
    File.join(network.build_directory, 'packages')
  end
  
  #---
  
  def packages
    @packages
  end
  
  def set_package(name, directory)
    @packages[name] = directory
  end
 
  #-----------------------------------------------------------------------------
  # Package interface operations
  
  def build_provider(name, project_reference, environment)
    provider_id = id(name)
    directory   = File.join(internal_path(build_directory), provider_id.to_s)
    success     = true
      
    info("Building package #{blue(name)} at #{purple(project_reference)} into #{green(directory)}", { :i18n => false })
      
    full_directory = File.join(network.directory, directory)
      
    unless packages.has_key?(provider_id)
      project = build_config.manage(:configuration, extended_config(:package, {
        :directory     => full_directory,
        :url           => project_reference,
        :create        => File.directory?(full_directory) ? false : true,
        :manage_ignore => false
      }))
      unless project
        warn("Package #{cyan(name)} failed to initialize", { :i18n => false })
        success = false
      end
           
      if success
        set_package(provider_id, full_directory)
        
        build_config.import(project)
        build_config.set_location(plugin_provider, name, directory)
      
        if project.get([ :builders, plugin_provider ], false)
          sub_packages = process_environment(project.get_hash([ :builders, plugin_provider ]), environment)          
          
          status  = parallel(:build_provider, sub_packages, environment)          
          success = false if status.values.include?(false)
        end
      end
    end
    success("Build of package #{blue(name)} finished", { :i18n => false }) if success
    success
  end
end
end
end

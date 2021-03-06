
module CORL
module Builder
class Identity < Nucleon.plugin_class(:CORL, :builder)

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

  def build_provider(name, project_reference, environment, options = {})
    provider_id = id(name)
    directory   = File.join(internal_path(build_directory), provider_id.to_s)
    config      = Config.ensure(options)
    success     = true

    info("Building identity #{blue(name)} at #{purple(project_reference)} into #{green(directory)}", { :i18n => false })

    full_directory = File.join(network.directory, directory)
    FileUtils.rm_rf(full_directory) if config.get(:clean, false)

    unless identities.has_key?(provider_id)
      project = build_config.manage(:project, extended_config(:identity, {
        :directory      => full_directory,
        :url            => project_reference,
        :create         => File.directory?(full_directory) ? false : true,
        :pull           => true,
        :internal_ip    => CORL.public_ip, # Needed for seeding Vagrant VMs
        :manage_ignore  => false,
        :nucleon_resave => true
      }))
      unless project
        warn("Identity #{cyan(name)} failed to initialize", { :i18n => false })
        success = false
      end

      if success
        # Make thid project private.
        FileUtils.chmod_R('go-wrx', full_directory)

        set_identity(provider_id, full_directory)
        build_config.set_location(plugin_provider, name, directory)
      end
    end
    #success("Build of identity #{blue(name)} finished", { :i18n => false }) if success
    success
  end
end
end
end

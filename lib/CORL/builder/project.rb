
module CORL
module Builder
class Project < Nucleon.plugin_class(:CORL, :builder)

  #-----------------------------------------------------------------------------
  # Project interface operations

  def build_provider(provider_path, project_reference, environment)
    path    = provider_path.to_s
    success = true

    info("Building project #{purple(project_reference)} into #{green(path)}", { :i18n => false })

    full_directory = File.join(network.directory, path)
    project        = build_config.manage(:project, extended_config(:project, {
      :directory     => full_directory,
      :url           => project_reference,
      :create        => File.directory?(full_directory) ? false : true,
      :pull          => true,
      :internal_ip   => CORL.public_ip, # Needed for seeding Vagrant VMs
      :manage_ignore => false,
      :corl_file     => false
    }))
    unless project
      warn("Project #{cyan(path)} failed to initialize", { :i18n => false })
      success = false
    end
    if success
      #success("Build of project #{blue(path)} finished", { :i18n => false })
      network.ignore(path)
    end
    success
  end
end
end
end

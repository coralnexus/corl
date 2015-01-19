
module Nucleon
module Action
module Network
class Vagrantfile < CORL.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super(:network, :vagrantfile, 800)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      codes :vagrant_backup_failure,
            :vagrant_save_failure,
            :network_save_failure

      register_bool :save
    end
  end

  #---

  def ignore
    node_ignore
  end

  #-----------------------------------------------------------------------------
  # Action operations

  def execute
    super do |node|
      ensure_network do
        generated_vagrantfile_name = File.join(CORL.lib_path, 'core', 'vagrant', 'Vagrantfile')
        project_vagrantfile_name   = File.join(network.directory, 'Vagrantfile')
        success                    = true

        corl_vagrantfile = Util::Disk.read(generated_vagrantfile_name)

        if settings[:save]
          if File.exists?(project_vagrantfile_name)
            backup_file = "#{project_vagrantfile_name}.backup"

            unless FileUtils.mv(project_vagrantfile_name, backup_file, :force => true)
              error('file_save', { :file => blue(backup_file) })
              myself.status = code.vagrant_backup_failure
              success       = false
            end
          end

          if success
            unless Util::Disk.write(project_vagrantfile_name, corl_vagrantfile)
              error('file_save', { :file => blue(project_vagrantfile_name) })
              myself.status = code.vagrant_save_failure
              success       = false
            end

            if success
              if network.save({ :files => 'Vagrantfile', :remote => settings[:net_remote], :message => "Saving new Vagrantfile.", :allow_empty => true })
                success('update', { :file => blue('Vagrantfile'), :remote_text => yellow(remote_message(settings[:net_remote])) })
              else
                error('update', { :file => blue('Vagrantfile') })
                myself.status = code.network_save_failure
              end
            end
          end
        else
          puts corl_vagrantfile
        end
      end
    end
  end
end
end
end
end

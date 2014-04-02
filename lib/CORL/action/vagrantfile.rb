
module CORL
module Action
class Vagrantfile < Plugin::CloudAction

  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do    
      codes :network_failure,
            :vagrant_backup_failure,
            :vagrant_save_failure,
            :network_save_failure
    end
  end
  
  #-----------------------------------------------------------------------------
  # Action operations
   
  def execute
    super do |node, network|
      info('corl.actions.vagrantfile.start')
      
      if network
        generated_vagrantfile_name = File.join(CORL.lib_path, 'core', 'vagrant', 'Vagrantfile')        
        project_vagrantfile_name   = File.join(network.directory, 'Vagrantfile')
        success                    = true
                
        corl_vagrantfile = Util::Disk.read(generated_vagrantfile_name)
        
        if File.exists?(project_vagrantfile_name)
          unless FileUtils.mv(project_vagrantfile_name, "#{project_vagrantfile_name}.backup", :force => true)
            myself.status = code.vagrant_backup_failure
            success       = false
          end
        end
        
        if success
          unless Util::Disk.write(project_vagrantfile_name, corl_vagrantfile)
            myself.status = code.vagrant_save_failure
            success       = false
          end
          
          if success
            unless network.save({ :files => 'Vagrantfile' })
              myself.status = code.network_save_failure
            end
          end
        end 
      else
        myself.status = code.network_failure
      end
    end
  end
end
end
end

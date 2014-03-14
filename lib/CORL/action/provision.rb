
module CORL
module Action
class Provision < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :network_failure,
            :provision_failure
    end
  end
  
  #-----------------------------------------------------------------------------
  # Operations
  
  def execute
    super do |node, network|
      if network && node
        info('corl.actions.provision.start')
        
        success = true
        
        if CORL.admin?
          unless node.build_time && File.directory?(network.build_directory)
            success = node.build
          end
        
          if success
            provisioner_info = node.provisioner_info   
        
            node.provisioners.each do |provider, collection|
              provider_info = provisioner_info[provider]
              profiles      = provider_info[:profiles]
          
              collection.each do |name, provisioner|
                build_profiles = provisioner.build_profiles
            
                if supported_profiles = provisioner.supported_profiles(profiles)
                  profile_success = provisioner.provision(supported_profiles)
                  success         = false unless profile_success
                end
              end
            end
            myself.status = code.provision_failure unless success
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


module CORL
module Action
class Provision < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :provision_failure
            
      register :dry_run, :bool, false
      register :environment, :str, ''
    end
  end
  
  #---
  
  def arguments
    [ :environment ]
  end

  #-----------------------------------------------------------------------------
  # Operations
  
  def execute
    super do |node, network|
      info('corl.actions.provision.start')
      
      ensure_node(node) do        
        success = true
        
        settings.delete(:environment) if settings[:environment] == ''
        
        if settings.has_key?(:environment)
          node.create_fact(:corl_environment, settings[:environment])
        end 
        
        if CORL.admin?
          unless node.build_time && File.directory?(network.build_directory)
            success = node.build(settings)
          end
        
          if success
            provisioner_info = node.provisioner_info   
        
            node.provisioners.each do |provider, collection|
              provider_info = provisioner_info[provider]
              profiles      = provider_info[:profiles]
          
              collection.each do |name, provisioner|
                if supported_profiles = provisioner.supported_profiles(profiles)
                  profile_success = provisioner.provision(supported_profiles, settings)
                  success         = false unless profile_success
                end
              end
            end
            myself.status = code.provision_failure unless success
          end
        end
      end
    end
  end
end
end
end

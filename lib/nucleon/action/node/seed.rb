
module Nucleon
module Action
module Node
class Seed < CORL.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :seed, 625)
  end
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :key_store_failure,
            :project_failure,
            :network_init_failure,
            :network_load_failure,
            :node_load_failure,
            :node_save_failure
      #---
      
      register :project_branch, :str, 'master'
      register :project_reference, :str, nil do |value|
        next true if value.nil?
        
        value           = value.to_sym
        project_plugins = CORL.loaded_plugins(:nucleon, :project)
        
        if @project_info = CORL.plugin_class(:nucleon, :project).translate_reference(value, true)
          provider = @project_info[:provider]
        else
          provider = value
        end
        
        unless project_plugins.keys.include?(provider.to_sym)
          warn('corl.actions.seed.errors.project_reference', { :value => value, :provider => provider, :choices => project_plugins.keys.join(', ') })
          next false
        end
        true
      end      
    end
  end
  
  #---
  
  def arguments
    [ :project_reference ]
  end

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node|
      info('corl.actions.seed.start')
      
      ensure_node(node) do
        admin_exec do
          network_path = lookup(:corl_network)
          backup_path  = File.join(Dir.tmpdir(), 'corl')
          
          info("Generating network SSH deploy keys", { :i18n => false })
          
          if keys = Util::SSH.generate.store
            if @project_info
              project_info = Config.new(@project_info)
            else
              project_info = Config.new({ :provider => :git })
            end
            
            info("Backing up current network configuration", { :i18n => false })
            FileUtils.rm_rf(backup_path)
            FileUtils.mv(network_path, backup_path)
            
            info("Seeding network configuration from #{settings[:project_reference]}", { :i18n => false })
            project = CORL.project(extended_config(:project, {
              :directory   => network_path,
              :reference   => project_info.get(:reference, nil),
              :url         => project_info.get(:url, settings[:project_reference]),
              :revision    => project_info.get(:revision, settings[:project_branch]),
              :create      => true,
              :pull        => true,
              :keys        => keys,
              :internal_ip => CORL.public_ip # Needed for seeding Vagrant VMs
            }), project_info[:provider])
        
            if project
              info("Finalizing network path and removing temporary backup", { :i18n => false })
              FileUtils.chmod_R(0600, network_path)
              FileUtils.rm_rf(backup_path)
              
              info("Reinitializing network", { :i18n => false })
              if network = init_network
                if network.load
                  if node = network.local_node(true)
                    info("Updating node network configurations", { :i18n => false })
                    myself.status = code.node_save_failure unless node.save  
                  else
                    myself.status = code.node_load_failure
                  end                  
                else
                  myself.status = code.network_load_failure    
                end
              else
                myself.status = code.network_init_failure
              end     
            else
              myself.status = code.project_failure  
            end            
          else
            myself.status = code.key_store_failure
          end
        end
      end
    end
  end
end
end
end
end

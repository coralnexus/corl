
module Nucleon
module Action
module Node
class Seed < Nucleon.plugin_class(:nucleon, :cloud_action)

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
            :network_load_failure,
            :node_load_failure,
            :node_save_failure
      #---

      register_project :project_reference
      register_str :project_branch, 'master'
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
      info('start')

      ensure_node(node) do
        admin_exec do
          network_path = lookup(:corl_network)
          backup_path  = File.join(Dir.tmpdir(), 'corl')

          info('deploy_keys')

          project_class = CORL.plugin_class(:nucleon, :project)

          if keys = Util::SSH.generate.store
            if @project_info = project_class.translate_reference(settings[:project_reference], true)
              project_info = Config.new(@project_info)
            else
              project_info = Config.new({ :provider => :git })
            end

            project_class.clear_provider(network_path)

            info('backup')
            FileUtils.rm_rf(backup_path)
            FileUtils.mv(network_path, backup_path)

            info('seeding')
            project = CORL.project(extended_config(:project, {
              :directory   => network_path,
              :reference   => project_info.get(:reference, nil),
              :url         => project_info.get(:url, settings[:project_reference]),
              :revision    => project_info.get(:revision, settings[:project_branch]),
              :create      => true,
              :pull        => true,
              :keys        => keys,
              :internal_ip => CORL.public_ip, # Needed for seeding Vagrant VMs,
              :new         => true
            }), project_info[:provider])

            if project
              info('finalizing')
              FileUtils.chmod_R(0600, network_path)
              FileUtils.rm_rf(backup_path)

              info('reinitializing')
              init_network

              if network.load
                if node = network.local_node(true)
                  #info('updating')
                  #myself.status = code.node_save_failure unless node.save
                else
                  myself.status = code.node_load_failure
                end
              else
                myself.status = code.network_load_failure
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

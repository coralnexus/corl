
module Nucleon
module Action
module Node
class Identity < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super(:node, :identity, 700)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      codes :identity_required, :identity_upload_failure

      register_str :name, nil
      register_project :identity
      register_nodes :identity_nodes

      register_bool :delete, false
    end
  end

  #---

  def ignore
    [ :nodes ]
  end

  def arguments
    [ :name, :identity_nodes ]
  end

  #-----------------------------------------------------------------------------
  # Operations

  def execute
    super do |local_node|
      ensure_network do
        if settings[:identity]
          # Get identity builder
          builder = network.identity_builder({ settings[:name] => settings[:identity] })
        else
          # Search for identity
          builder            = network.identity_builder
          identity_directory = File.join(builder.build_directory, settings[:name])

          if File.directory?(identity_directory)
            identity_nucleon_file = File.join(identity_directory, '.nucleon')

            if File.exists?(identity_nucleon_file)
              json_data           = Util::Disk.read(identity_nucleon_file)
              project_info        = symbol_map(Util::Data.parse_json(json_data))
              settings[:identity] = "#{project_info[:provider]}:::#{project_info[:edit]}[#{project_info[:revision]}]"
            end
          end

          if settings[:identity]
            # Get identity builder
            info('using_identity', { :identity => settings[:identity], :directory => identity_directory })
            builder = network.identity_builder({ settings[:name] => settings[:identity] })
          else
            warn('identity_required')
            myself.status = code.identity_required
          end
        end

        # Build identity into local network project
        if myself.status == code.success && ( settings[:delete] || builder.build(local_node) )
          identity_directory = File.join(builder.build_directory, settings[:name])

          # Loop over all nodes to assign identity to (or delete)
          success = network.batch(settings[:identity_nodes], settings[:node_provider], settings[:parallel]) do |node|
            if settings[:delete]
              info('start_delete', { :provider => node.plugin_provider, :name => node.plugin_name })
            else
              info('start_add', { :provider => node.plugin_provider, :name => node.plugin_name })
            end

            # Lookup remote network path
            success                        = true
            remote_network_directory       = node.lookup(:corl_network)
            remote_config_directory        = File.join(remote_network_directory, network.config_directory.sub(/#{network.directory}#{File::SEPARATOR}/, ''))
            remote_identity_base_directory = File.join(remote_network_directory, builder.build_directory.sub(/#{network.directory}#{File::SEPARATOR}/, ''))
            remote_identity_directory      = File.join(remote_identity_base_directory, settings[:name])

            # Ensure proper remote directories are ready for identity
            result  = node.cli.mkdir('-p', remote_identity_base_directory)
            success = false unless result.status == code.success

            if success
              result  = node.cli.rm('-Rf', remote_identity_directory)
              success = false unless result.status == code.success

              # Send identity through SCP to remote machine
              success = node.send_files(identity_directory, remote_identity_directory, nil, '0700') if success && ! settings[:delete]
            end
            success
          end

          if success && settings[:delete]
            # Remove local identity last
            info('local_delete', { :directory => identity_directory })
            FileUtils.rm_rf(identity_directory)
          end
        end
        myself.status = code.batch_error unless success
      end
    end
  end
end
end
end
end

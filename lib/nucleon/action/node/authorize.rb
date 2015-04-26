
module Nucleon
module Action
module Node
class Authorize < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super(:node, :authorize, 555)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      codes :key_store_failure

      register_bool :reset, false
      register_str :public_key, nil
      register_str :ssh_user, nil
    end
  end

  #---

  def arguments
    [ :public_key, :ssh_user ]
  end

  #-----------------------------------------------------------------------------
  # Operations

  def execute
    super do |node|
      info('start', { :public_key => settings[:public_key] })

      ensure_node(node) do
        ssh_path        = Util::SSH.key_path(settings[:ssh_user])
        authorized_keys = File.join(ssh_path, 'authorized_keys')
        public_key      = settings[:public_key].strip
        key_found       = false

        File.delete(authorized_keys) if settings[:reset]

        if File.exists?(authorized_keys)
          Util::Disk.read(authorized_keys).split("\n").each do |line|
            if line.strip.include?(public_key)
              key_found = true
              break
            end
          end
        end
        unless key_found
          unless Util::Disk.write(authorized_keys, "#{public_key}\n", { :mode => 'a' })
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

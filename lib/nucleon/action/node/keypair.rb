
module Nucleon
module Action
module Node
class Keypair < Nucleon.plugin_class(:nucleon, :cloud_action)

  include Mixin::Action::Keypair

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super(:node, :keypair, 545)
  end

  #----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      codes :key_failure

      register :json, :bool, true
      register :both, :bool, false
      keypair_config
    end
  end

  #---

  def ignore
    node_ignore
  end

  #-----------------------------------------------------------------------------
  # Operations

  def execute
    super do |node|
      if keys = keypair
        ui.info("\n", { :prefix => false })
        ui_group(Util::Console.cyan("#{keys.type.upcase} SSH keypair")) do |ui|
          render_json = lambda do
            private_key = Util::Console.blue(Util::Data.to_json(keys.encrypted_key, true))
            ssh_key     = keys.ssh_key.gsub(/^ssh\-[a-z]+\s+/, '')
            ssh_key     = Util::Console.green(Util::Data.to_json(ssh_key, true))

            ui.info("-----------------------------------------------------")
            ui.info(yellow("SSH JSON string"))
            ui.info("SSH private key:\n#{private_key}", { :prefix => false })
            ui.info("SSH public key:\n#{ssh_key}", { :prefix => false })
            ui.info("\n", { :prefix => false })
          end

          render_file = lambda do
            private_key = Util::Console.blue(keys.encrypted_key)
            ssh_key     = Util::Console.green(keys.ssh_key)

            ui.info("-----------------------------------------------------")
            ui.info(yellow("SSH file rendering"))
            ui.info("SSH private key:\n#{private_key}", { :prefix => false })
            ui.info("SSH public key:\n#{ssh_key}", { :prefix => false })
            ui.info("\n", { :prefix => false })
          end

          if settings[:both]
            render_json.call
            render_file.call
          else
            if settings[:json]
              render_json.call
            else
              render_file.call
            end
          end
        end
      else
        myself.status = code.key_failure
      end
    end
  end
end
end
end
end


module Nucleon
module Action
module Node
class Keypair < CORL.plugin_class(:nucleon, :cloud_action)
  
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
    super do |node, network|
      if keys = keypair
        ui.info("\n", { :prefix => false })
        ui_group(Util::Console.cyan("#{keys.type.upcase} SSH keypair")) do |ui|
          ui.info("-----------------------------------------------------")
        
          if settings[:json]
            private_key = Util::Console.blue(Util::Data.to_json(keys.encrypted_key, true))
            ssh_key     = keys.ssh_key.gsub(/^ssh\-[a-z]+\s+/, '')           
            ssh_key     = Util::Console.green(Util::Data.to_json(ssh_key, true))
          else
            private_key = Util::Console.blue(keys.encrypted_key)
            ssh_key     = Util::Console.green(keys.ssh_key)       
          end
          
          ui.info("SSH private key:\n#{private_key}")
          ui.info("SSH public key:\n#{ssh_key}")
          ui.info("\n", { :prefix => false }) 
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

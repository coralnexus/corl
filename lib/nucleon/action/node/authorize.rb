
module Nucleon
module Action
module Node
class Authorize < CORL.plugin_class(:nucleon, :cloud_action)
  
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
      
      register :reset, :bool, false
      register :public_key, :str, nil
    end
  end
  
  #---
  
  def arguments
    [ :public_key ]
  end

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node|
      info('corl.actions.authorize.start')
      
      ensure_node(node) do
        ssh_path        = Util::SSH.key_path
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

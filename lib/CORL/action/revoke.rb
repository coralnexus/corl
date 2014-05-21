
module CORL
module Action
class Revoke < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :key_remove_failure
      
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
    super do |node, network|
      info('corl.actions.revoke.start')
      
      ensure_node(node) do
        ssh_path        = Util::SSH.key_path
        authorized_keys = File.join(ssh_path, 'authorized_keys')        
        public_key      = settings[:public_key].strip
        output_keys     = []
                
        if File.exists?(authorized_keys)
          Util::Disk.read(authorized_keys).split("\n").each do |line|
            if line.strip.include?(public_key)
              key_found = true
            else
              output_keys << public_key
            end            
          end
        end
        unless key_found
          unless Util::Disk.write(authorized_keys, output_keys.join("\n"))
            myself.status = code.key_revoke_failure
          end
        end
      end
    end
  end
end
end
end
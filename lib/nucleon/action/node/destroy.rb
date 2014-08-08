
module Nucleon
module Action
module Node
class Destroy < Nucleon.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :destroy, 580)
  end
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      register_bool :force, false
      
      register_nodes :destroy_nodes
    end
  end
  
  #---
  
  def ignore
    [ :nodes ]
  end
  
  def arguments
    [ :destroy_nodes ]
  end

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |local_node|
      ensure_network do
        if settings[:force]
          answer = 'YES'
        else
          message = render_message('prompt', { :operation => :ask }) + "\n\n"
        
          array(settings[:destroy_nodes]).each do |hostname|
            message << "  #{hostname}\n"
          end
        
          message << "\n" + render_message('yes_query', { :operation => :ask, :yes => 'YES' }) + ' '
          answer = ask(message)
        end
        
        if answer.upcase == 'YES'
          batch_success = network.batch(settings[:destroy_nodes], settings[:node_provider], settings[:parallel]) do |node|
            info('start', { :provider => node.plugin_provider, :name => node.plugin_name })
            node.destroy
          end
          myself.status = code.batch_error unless batch_success
        end
      end
    end
  end
end
end
end
end

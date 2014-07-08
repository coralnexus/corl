
module Nucleon
module Action
module Node
class Status < CORL.plugin_class(:nucleon, :cloud_action)
  
  include Mixin::Action::Registration
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :status, 800)
  end
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      register_nodes :status_nodes
    end
  end
  
  #---
  
  def ignore
    [ :nodes ]
  end
  
  def arguments
    [ :status_nodes ]
  end
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |local_node, network|
      ensure_network(network) do
        batch_success = network.batch(settings[:status_nodes], settings[:node_provider], settings[:parallel]) do |node|
          state       = node.state(true).to_sym
          ssh_enabled = ''
          
          case state
          when :running, :active
            state = green(state.to_s)
            
            result = node.cli.test :true
            
            if result.status == code.success
              ssh_enabled = ' [SSH connected]'
            else
              ssh_enabled = " [SSH failed with status #{result.status}]"      
            end
            
          when :stopped, :aborted
            state = red(state.to_s)
          end 
          info(state + "#{ssh_enabled}", { :i18n => false, :prefix_text => purple(node.plugin_name) })
          true
        end
        myself.status = code.batch_error unless batch_success
      end
    end
  end
end
end
end
end

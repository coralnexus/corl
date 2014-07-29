
module Nucleon
module Action
module Node
class Exec < Nucleon.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :exec, 605)
  end
 
  #----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      register :command, :array, nil
    end
  end
  
  #---
  
  def arguments
    [ :command ]
  end
 
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node|
      ensure_node(node) do
        if settings[:command].length > 1
          settings[:command].collect! do |value|
            if value.strip.match(/\s+/)
              value = "\"#{value}\""
            end
            value
          end
        end
        
        command_str   = settings[:command].join(' ')
        result        = node.exec({ :commands => [ command_str ] }).first
        myself.status = result.status
      end
    end
  end
end
end
end
end

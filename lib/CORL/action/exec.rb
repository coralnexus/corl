
module CORL
module Action
class Exec < Plugin::CloudAction
 
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
    super do |node, network|
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


module CORL
module Action
class Exec < Plugin::CloudAction
 
  #----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :network_failure
            
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
      if network && node
        settings[:command].collect! do |value|
          if value.strip.match(/\s+/)
            value = "\"#{value}\""
          end
          value
        end
        
        command_str   = settings[:command].join(' ')
        result        = node.exec({ :commands => [ command_str ] }).first
        myself.status = result.status
      else
        myself.status = code.network_failure
      end
    end
  end
end
end
end

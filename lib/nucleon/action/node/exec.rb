
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
      if settings[:command].length > 1
        settings[:command].collect! do |value|
          if value.strip.match(/\s+/)
            value = "\"#{value}\""
          end
          value
        end
      end
      command_str = settings[:command].join(' ')

      if node
        result = node.exec({ :commands => [ command_str ] }).first
      else
        result = CORL.cli_run(command_str)
      end
      myself.status = result.status
    end
  end
end
end
end
end

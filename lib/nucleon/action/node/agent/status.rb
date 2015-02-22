
module Nucleon
module Action
module Node
module Agent
class Status < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super([ :node, :agent ], :status, 650)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      register_array :provider, nil
      register_translator :format, :json
    end
  end

  #---

  def arguments
    [ :provider ]
  end

  #-----------------------------------------------------------------------------
  # Operations

  def execute
    super do |node|
      ensure_node(node) do
        translator     = CORL.translator({}, settings[:format])

        agent_provider = "agent_#{settings[:provider].join('_')}"
        agent_record   = node.agent(agent_provider)

        agent_record[:running] = node.agent_running(agent_provider)

        myself.result = agent_record
        $stderr.puts translator.generate(result)
      end
    end
  end
end
end
end
end
end

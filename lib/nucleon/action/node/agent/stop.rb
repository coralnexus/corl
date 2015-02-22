
module Nucleon
module Action
module Node
module Agent
class Stop < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super([ :node, :agent ], :stop, 640)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      register_array :provider, nil
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
        node.remove_agent("agent_#{settings[:provider].join('_')}")
      end
    end
  end
end
end
end
end
end

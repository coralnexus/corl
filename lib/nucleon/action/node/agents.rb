
module Nucleon
module Action
module Node
class Agents < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super(:node, :agents, 800)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      register_translator :format, :json
    end
  end

  #-----------------------------------------------------------------------------
  # Operations

  def execute
    super do |node|
      ensure_node(node) do
        translator    = CORL.translator({}, settings[:format])
        agent_records = node.agents

        agent_records.each do |provider, agent_options|
          agent_records[provider][:running] = node.agent_running(provider)
        end

        myself.result = agent_records
        $stderr.puts translator.generate(result) unless result.empty?
      end
    end
  end
end
end
end
end

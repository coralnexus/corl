
nucleon_require(File.dirname(__FILE__), :cloud_action)

#---

module Nucleon
module Plugin
class Agent < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe_base(group = nil, action = 'unknown', weight = -1000, description = nil, help = nil, provider_override = nil)
    group = array(group).collect! {|item| item.to_sym }
    group = [ :agent ] | group
    super(group.uniq, action, weight, description, help, provider_override)
  end

  #-----------------------------------------------------------------------------
  # Property accessor / modifiers

  def configure
    super do
      yield if block_given?
      agent_config
    end
  end

  #---

  def arguments
    # Don't use or the default log file naming will screw up due to having to
    # move daemonization to the corl loader.
    #
    # See: lib/corl.rb
    #
    []
  end

  #-----------------------------------------------------------------------------
  # Settings

  def pid
    settings[:pid]
  end

  #---

  def agent_config
    register_bool :log, true, 'corl.core.action.agent.options.log'
    register_bool :truncate_log, true, 'corl.core.action.agent.options.truncate_log'

    register_str :log_file, "/var/log/corl/#{plugin_provider}.log", 'corl.core.action.agent.options.log_file'
  end

  #-----------------------------------------------------------------------------
  # Operations

  def execute(use_network = true, &block)
    super do |node|
      ensure_network do
        trap(:INT) do
          safe_exit
        end

        add_agent(node)
        block.call(node)
        remove_agent(node) if myself.status == code.success
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Utilities

  def add_agent(node)
    settings[:pid] = Process.pid

    stored_config = Util::Data.clean(settings.export)
    stored_config = Util::Data.rm_keys(stored_config, [ :node_provider, :nodes, :color, :version ])

    node.add_agent(plugin_provider, stored_config)
  end
  protected :add_agent

  #---

  def remove_agent(node)
    node.remove_agent(plugin_provider)
  end
  protected :remove_agent

  #---

  def safe_exit
    finalize_execution
    exit status
  end
  protected :safe_exit
end
end
end

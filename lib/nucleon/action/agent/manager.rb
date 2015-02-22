
module Nucleon
module Action
module Agent
class Manager < Nucleon.plugin_class(:nucleon, :agent)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super(nil, :manager, 1100)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      codes :network_failure

      register_int :sleep_interval, 15
      register_int :network_retries, 3
      register_int :agent_restart_retries, 2
    end
  end

  #---

  def arguments
    [ :sleep_interval ]
  end

  #-----------------------------------------------------------------------------
  # Operations

  def execute
    super do |node|
      ensure_node(node) do
        network_retry       = 0
        agent_restart_retry = {}

        while status == code.success
          if network.load({ :remote => settings[:net_remote], :pull => true })
            network_retry = 0

            node.agents.each do |provider, agent_options|
              agent_restart_retry[provider] = 0 unless agent_restart_retry.has_key?(provider)

              unless provider == :agent_manager || node.agent_running(provider)
                if agent_restart_retry[provider] < settings[:agent_restart_retries]
                  command = "corl #{agent_options[:args]} --log_level=warn"
                  result  = node.exec({ :commands => [ command ] }).first

                  if result.status == code.success
                    agent_restart_retry[provider] = 0
                  else
                    agent_restart_retry[provider] += 1
                  end
                end
              end
            end
          elsif network_retry < settings[:network_retries]
            network_retry += 1
          else
            myself.status = code.network_failure
          end
          sleep settings[:sleep_interval]
        end
      end
    end
  end
end
end
end
end


module Nucleon
module Action
module Network
class Inspect < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super(:network, :inspect, 955)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      codes :configuration_parse_failed

      register_array :elements
      register_translator :format, :json
    end
  end

  #---

  def ignore
    node_ignore
  end

  def arguments
    [ :elements ]
  end

  #-----------------------------------------------------------------------------
  # Operations

  def execute
    super do |node|
      ensure_network do
        if settings[:elements].empty?
          data = network.config.export
        else
          data = network.config.get(settings[:elements])
        end
        if network.config.status == code.success
          render data, :format => settings[:format]
        else
          myself.status = code.configuration_parse_failed
        end
      end
    end
  end
end
end
end
end

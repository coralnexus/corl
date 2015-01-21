
module Nucleon
module Action
module Node
class Build < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super(:node, :build, 620)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      register_str :environment
      register_array :providers
      register_bool :clean
    end
  end

  #---

  def arguments
    [ :environment ]
  end

  #-----------------------------------------------------------------------------
  # Operations

  def execute
    super do |node|
      info('start')

      ensure_node(node) do
        settings.delete(:environment) if settings[:environment] == ''

        if settings.has_key?(:environment)
          CORL.create_fact(:corl_environment, settings[:environment])
        end
        node.build(settings)
      end
    end
  end
end
end
end
end

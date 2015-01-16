
module VagrantPlugins
module CORL
class BaseAction

  #-----------------------------------------------------------------------------
  # Constructor / Destructor

  def initialize(app, env)
    @app     = app
    @env     = env[:machine].env

    @network = nil
    @node    = nil
    @vm      = nil

    if @corl_config_loaded = ::CORL.vagrant_config_loaded?
      if @network = ::CORL::Vagrant::Config.load_network(env[:root_path])
        @vm   = env[:machine]
        @node = network.node(:vagrant, @vm.name) if @vm
      end
    end

    unless ::CORL::Vagrant.command
      # Hackish solution to ensure our code has access to Vagrant machines.
      # This serves as a Vagrant VM manager.
      ::CORL::Vagrant.command = Command::Launcher.new([], @env)
    end
  end

  #-----------------------------------------------------------------------------
  # Property accessor / modifiers

  attr_reader :network, :node, :vm

  #-----------------------------------------------------------------------------
  # Action execution

  def call(env)
    yield if block_given? && @corl_config_loaded && @network && @node
  end
end
end
end

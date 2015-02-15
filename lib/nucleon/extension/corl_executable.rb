
module Nucleon
module Extension
class CorlExecutable < Nucleon.plugin_class(:nucleon, :extension)

  def executable_load(config)
    network_path = Nucleon.fact(:corl_network)
    Nucleon.load_plugins(network_path) if Dir.pwd != network_path
  end
end
end
end


nucleon_require(File.dirname(__FILE__), :cloud_action)

#---

module Nucleon
module Plugin
class CloudActionWrapper < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Operations

  def execute(use_network = true, &block)
    super do |node|
      bin_dir = File.join(network.directory, 'bin')
      bin_dir = ( File.directory?(bin_dir) ? bin_dir : network.directory )

      Dir.chdir(bin_dir) do
        result        = node.exec({ :commands => [ block.call(node) ] }).first
        myself.status = result.status
      end
    end
  end
end
end
end

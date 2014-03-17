#
# corl_initialize.rb
#
# Initialize the CORL plugin system through Puppet
#
module Puppet::Parser::Functions
  newfunction(:corl_initialize, :doc => <<-EOS
This function initializes the CORL plugin system through Puppet.
    EOS
) do |args|    
    CORL.run do
      # Register all Nucleon plugins defined by Puppet modules.
      CORL::Util::Puppet.register_plugins({ :puppet_scope => self })
      
      # Make sure defaults are evaluated first!
      if compiler.node.classes.is_a?(Hash)
        compiler.node.classes.each do |name, parameters|
          if name.match(/::default:?/)            
            compiler.evaluate_classes({ name => parameters }, self, false)
          end
        end
      end
    end
  end
end

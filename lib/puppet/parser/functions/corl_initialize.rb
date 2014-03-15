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
      CORL::Util::Puppet.register_plugins({ :puppet_scope => self })
    end
  end
end

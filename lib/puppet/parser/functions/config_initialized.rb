#
# config_initialized.rb
#
# This function checks if the configuration system is fully configured 
# and ready to query.
#
module Puppet::Parser::Functions
  newfunction(:config_initialized, :type => :rvalue, :doc => <<-EOS
This function checks if Hiera is fully configured and ready to query.
    EOS
) do |args|
    
    value = nil
    CORL.run do
      options = ( args[0].is_a?(Hash) ? args[0] : {} )
    
      config = CORL::Config.init_flat(options, [ :init, :config_initialized ], {
        :hiera_scope  => self,
        :puppet_scope => self,
        :init_fact    => 'corl_config_ready'
      })        
      value = CORL::Config.initialized?(config)
    end
    return value
  end
end

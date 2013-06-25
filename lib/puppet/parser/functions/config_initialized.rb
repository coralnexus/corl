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
    Coral.run do
      options = ( args[0].is_a?(Hash) ? args[0] : {} )
    
      contexts = function_option_contexts([ 'init', 'config_initialized' ]) 
      config   = Coral::Config.init(options, contexts, {
        :scope     => self,
        :init_fact => 'hiera_ready' 
      })        
      value = Coral::Config.initialized?(config)
    end
    return value
  end
end

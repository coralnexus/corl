#
# module_param.rb
#
# This function performs a lookup for a variable value in various locations
# following this order
# - Hiera backend, if present (modulename prefix)
# - ::coral::default::{modulename}::{varname} (configurable!!)
# - ::{modulename}::default::{varname}
# - {default parameter}
#
module Puppet::Parser::Functions
  newfunction(:module_param, :type => :rvalue, :doc => <<-EOS
This function performs a lookup for a variable value in various locations following this order:
- Hiera backend, if present (modulename prefix)
- ::data::default::{modulename}_{varname} (configurable!!)
- ::{modulename}::default::{varname}
- {default parameter}
If no value is found in the defined sources, it returns an empty string ('')
    EOS
) do |args|
    
    value = nil
    Coral.run do
      raise(Puppet::ParseError, "module_param(): Define at least the variable name " +
        "given (#{args.size} for 1)") if args.size < 1
      
      var_name = args[0]
      default  = ( args.size > 1 ? args[1] : '' )
      options  = ( args.size > 2 ? args[2] : {} )
    
      module_name      = self.source.module_name
      module_var_name  = "#{module_name}::#{var_name}"
      default_var_name = "#{module_name}::default::#{var_name}"
      
      config = Coral::Config.init(options, [ :param, :module_param ], module_name, {
        :hiera_scope  => self,
        :puppet_scope => self,
        :search       => 'core::default',
        :search_name  => false,
        :init_fact    => 'hiera_ready',
        :force        => true,
        :merge        => true
      })
      value = Coral::Config.lookup([ module_var_name, default_var_name ], default, config)
    end
    return value
  end
end

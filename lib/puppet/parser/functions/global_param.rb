#
# global_param.rb
#
# This function performs a lookup for a variable value in various locations
# following this order
# - Hiera backend, if present (no prefix)
# - ::global::default::varname
# - ::varname
# - {default parameter}
#
module Puppet::Parser::Functions
  newfunction(:global_param, :type => :rvalue, :doc => <<-EOS
This function performs a lookup for a variable value in various locations following this order:
- Hiera backend, if present (no prefix)
- ::global::default::varname
- ::varname
- {default parameter}
If no value is found in the defined sources, it returns an empty string ('')
    EOS
) do |args|
    
    value = nil
    CORL.run do
      raise(Puppet::ParseError, "global_param(): Define at least the variable name " +
        "given (#{args.size} for 1)") if args.size < 1

      var_name = args[0]
      default  = ( args.size > 1 ? args[1] : '' )
      options  = ( args.size > 2 ? args[2] : {} )
    
      config = CORL::Config.init_flat(options, [ :param, :global_param, var_name ], {
        :provisioner     => :puppetnode,
        :hiera_scope     => self,
        :puppet_scope    => self,
        :search          => 'core::default',
        :force           => true,
        :merge           => true,
        :undefined_value => :undef
      })
      value = CORL::Config.lookup(var_name, default, config)
    end
    return value
  end
end

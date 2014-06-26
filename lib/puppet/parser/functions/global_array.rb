#
# global_array.rb
#
# See: global_param.rb
#
module Puppet::Parser::Functions
  newfunction(:global_array, :type => :rvalue, :doc => <<-EOS
This function performs a lookup for a variable value in various locations:
See: global_params()
If no value is found in the defined sources, it returns an empty array ([])
    EOS
) do |args|
    
    value = nil
    CORL.run do
      raise(Puppet::ParseError, "global_array(): Define at least the variable name " +
        "given (#{args.size} for 1)") if args.size < 1
    
      var_name = args[0]
      default  = ( args.size > 1 ? args[1] : [] ) 
      options  = ( args.size > 2 ? args[2] : {} )
      node     = CORL::Provisioner::Puppetnode.node
    
      config = CORL::Config.init_flat(options, [ :param, :global_array, var_name ], {
        :provisioner     => :puppetnode,
        :hiera_scope     => self,
        :puppet_scope    => self,
        :search          => 'core::default',
        :force           => true,
        :merge           => true,
        :undefined_value => :undef
      })
      value = node.lookup_array(var_name, default, config)
    end
    return value
  end
end

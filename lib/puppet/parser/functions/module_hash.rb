#
# module_hash.rb
#
module Puppet::Parser::Functions
  newfunction(:module_hash, :type => :rvalue, :doc => <<-EOS
This function performs a lookup for a variable value in various locations:
See: module_params()
If no value is found in the defined sources, it returns an empty hash ({})
    EOS
) do |args|
    
    value = nil
    CORL.run do
      raise(Puppet::ParseError, "module_hash(): Define at least the variable name " +
        "given (#{args.size} for 1)") if args.size < 1

      var_name = args[0]
      default  = ( args.size > 1 ? args[1] : {} )
      options  = ( args.size > 2 ? args[2] : {} )
    
      module_name = parent_module_name
      node        = CORL::Provisioner::Puppetnode.node
      
      if module_name
        module_var_name = "#{module_name}::#{var_name}"
        
        config = CORL::Config.init(options, [ :param, :module_hash, var_name ], module_name, {
          :provisioner     => :puppetnode,
          :hiera_scope     => self,
          :puppet_scope    => self,
          :search          => 'core::default',
          :search_name     => false,
          :force           => true,
          :merge           => true,
          :undefined_value => :undef
        })
        value = node.lookup_hash(module_var_name, default, config)
      end
    end
    return value
  end
end

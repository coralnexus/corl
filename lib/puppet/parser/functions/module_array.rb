#
# module_array.rb
#
module Puppet::Parser::Functions
  newfunction(:module_array, :type => :rvalue, :doc => <<-EOS
This function performs a lookup for a variable value in various locations:
See: module_params()
If no value is found in the defined sources, it returns an empty array ([])
    EOS
) do |args|
    
    value = nil
    CORL.run do
      raise(Puppet::ParseError, "module_array(): Define at least the variable name " +
        "given (#{args.size} for 1)") if args.size < 1

      var_name = args[0]
      default  = ( args.size > 1 ? args[1] : [] )
      options  = ( args.size > 2 ? args[2] : {} )
      
      module_name     = self.source.module_name
      module_var_name = "#{module_name}::#{var_name}"
      
      config = CORL::Config.init(options, [ :param, :module_array ], module_name, {
        :provisioner  => :puppetnode,
        :hiera_scope  => self,
        :puppet_scope => self,
        :search       => 'core::default',
        :search_name  => false,
        :force        => true,
        :merge        => true
      })
      value = CORL::Config.lookup_array(module_var_name, default, config)
    end
    return value
  end
end

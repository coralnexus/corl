#
# coral_include.rb
#
# This function includes classes based on dynamic configurations.
# following this order
# - Hiera backend, if present (no prefix)
# - ::data::default::varname
# - ::varname
# - {default parameter}
#
module Puppet::Parser::Functions
  newfunction(:coral_include, :doc => <<-EOS
This function performs a lookup for a variable value in various locations following this order:
- Hiera backend, if present (no prefix)
- ::data::default::varname
- ::varname
- {default parameter}
If no value is found in the defined sources, it does not include any classes.
    EOS
) do |args|
    
    Coral.run do
      raise(Puppet::ParseError, "coral_include(): Define at least the variable name " +
        "given (#{args.size} for 1)") if args.size < 1

      var_name   = args[0]
      parameters = ( args.size > 1 ? args[1] : {} )
      options    = ( args.size > 2 ? args[2] : {} ) 
            
      unless Coral.provisioner(:puppet).include(var_name, parameters, options)
        # Throw an error if we didn't evaluate all of the classes.
        str = "Could not find class"
        str += "es" if missing.length > 1

        str += " " + missing.join(", ")

        if n = namespaces and ! n.empty? and n != [""]
          str += " in namespaces #{@namespaces.join(", ")}"
        end
        self.fail Puppet::ParseError, str
      end      
    end
  end
end

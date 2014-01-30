#
# global_options.rb
#
# This function sets globally available default options for other functions.
#
module Puppet::Parser::Functions
  newfunction(:global_options, :doc => <<-EOS
This function sets globally available default options for other functions:
EOS
) do |args|
    
    Coral.run do
      raise(Puppet::ParseError, "global_options(): Define a context name and at least one option name/value pair: " +
        "given (#{args.size} for 2)") if args.size < 2

      contexts = args[0]
      options  = args[1]
      force    = ( args[2] ? true : false )
      
      Coral::Config.set_options(contexts, options, force)
    end
  end
end

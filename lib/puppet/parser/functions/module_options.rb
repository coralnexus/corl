#
# module_options.rb
#
# This function sets module level default options for other functions.
#
module Puppet::Parser::Functions
  newfunction(:module_options, :doc => <<-EOS
This function sets module level default options for other functions:
EOS
) do |args|
    
    CORL.run do
      raise(Puppet::ParseError, "module_options(): Define a context name and at least one option name/value pair: " +
        "given (#{args.size} for 2)") if args.size < 2

      contexts = args[0]
      options  = args[1]
      force    = ( args[2] ? true : false )
      
      CORL::Config.set_options(CORL::Util::Data.prefix(self.source.module_name, contexts), options, force)
    end
  end
end

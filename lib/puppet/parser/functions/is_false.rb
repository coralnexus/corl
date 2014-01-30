#
# is_false.rb
#
# Checks whether a given string or boolean value is false.
#
module Puppet::Parser::Functions
  newfunction(:is_false, :type => :rvalue, :doc => <<-EOS
This function checks whether a given value is false.
    EOS
) do |args|
    
    value = nil
    Coral.run do
      raise(Puppet::ParseError, "is_false(): Must have a value to check; " +
        "given (#{args.size} for 1)") if args.size < 1
      
      value = Coral::Util::Data.false?(args[0])
    end
    return value
  end
end

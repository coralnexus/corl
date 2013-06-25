#
# name.rb
#
# Returns a standardized form of a given resource name.
#
module Puppet::Parser::Functions
  newfunction(:name, :type => :rvalue, :doc => <<-EOS
This function returns a standardized form of a given resource name.
    EOS
) do |args|
    
    name = nil
    Coral.run do
      raise(Puppet::ParseError, "name(): Must have a resource name specified; " +
        "given (#{args.size} for 1)") if args.size < 1
      
      name = Coral::Resource.to_name(args[0], :puppet)
    end
    return name
  end
end

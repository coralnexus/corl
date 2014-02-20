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
    CORL.run do
      raise(Puppet::ParseError, "name(): Must have a resource name specified; " +
        "given (#{args.size} for 1)") if args.size < 1
      
      name = CORL.provisioner(:puppet).to_name(args[0])
    end
    return name
  end
end

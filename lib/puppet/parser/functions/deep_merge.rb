#
# deep_merge.rb
#
# Merges multiple hashes together recursively.
#
module Puppet::Parser::Functions
  newfunction(:deep_merge, :type => :rvalue, :doc => <<-EOS
This function Merges multiple hashes together recursively.
    EOS
) do |args|
    
    value = nil
    Coral.run do
      raise(Puppet::ParseError, "deep_merge(): Define at least one hash " +
        "given (#{args.size} for 1)") if args.size < 1
      
      value = Coral::Util::Data.merge(args)
    end
    return value
  end
end

#
# corl_merge.rb
#
# Merges multiple hashes together recursively.
#
module Puppet::Parser::Functions
  newfunction(:corl_merge, :type => :rvalue, :doc => <<-EOS
This function merges multiple hashes together recursively.
    EOS
) do |args|
    
    value = nil
    CORL.run do
      raise(Puppet::ParseError, "corl_merge(): Define at least one hash " +
        "given (#{args.size} for 1)") if args.size < 1
      
      value = CORL::Util::Data.merge(args)
    end
    return value
  end
end

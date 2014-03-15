#
# interpolate.rb
#
# Interpolate values from one hash to another for configuration injection.
#
module Puppet::Parser::Functions
  newfunction(:interpolate, :type => :rvalue, :doc => <<-EOS
This function interpolates values from one hash to another for configuration injections.
    EOS
) do |args|
    
    value = nil
    CORL.run do
      raise(Puppet::ParseError, "interpolate(): Define at least a property name with optional source configurations " +
        "given (#{args.size} for 2)") if args.size < 1
      
      value   = args[0]
      data    = ( args.size > 1 ? args[1] : {} )
      options = ( args.size > 2 ? args[2] : {} )
      
      config = CORL::Config.init_flat(options, [ :data, :interpolate ])
      value  = CORL::Util::Data.interpolate(value, data, config.export)
    end
    return value
  end
end

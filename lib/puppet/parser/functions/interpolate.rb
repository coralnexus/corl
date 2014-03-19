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
      
      module_name = parent_module_name
      contexts    = [ :data, :interpolate ]
      
      if module_name
        config = CORL::Config.init(options, contexts, module_name)  
      else
        config = CORL::Config.init_flat(options, contexts)
      end
      
      value = CORL::Util::Data.interpolate(value, data, config.export)
      
      if config.get(:debug, false)
        display_name = module_name ? module_name : "toplevel"
              
        CORL.ui.info("\n", { :prefix => false })
        CORL.ui_group(CORL::Util::Console.cyan("#{display_name} interpolation")) do |ui|
          ui.info("-----------------------------------------------------")
        
          source_dump        = CORL::Util::Console.blue(CORL::Util::Data.to_json(args[0], true))
          interpolation_data = CORL::Util::Console.grey(CORL::Util::Data.to_json(data, true))
          value_dump         = CORL::Util::Console.green(CORL::Util::Data.to_json(value, true))       
        
          ui.info("Original:\n#{source_dump}")
          ui.info("Interpolation data:\n#{interpolation_data}")
          ui.info("Interpolated:\n#{value_dump}")
          ui.info("\n", { :prefix => false }) 
        end
      end
    end
    return value
  end
end

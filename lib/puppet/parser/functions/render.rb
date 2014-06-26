#
# render.rb
#
# Returns the string-ified form of a given value or set of values.
#
module Puppet::Parser::Functions
  newfunction(:render, :type => :rvalue, :doc => <<-EOS
This function returns the string-ified form of a given value.
    EOS
) do |args|
    
    value = nil
    CORL.run do
      raise(Puppet::ParseError, "render(): Must have a template class name and an optional source value specified; " +
        "given (#{args.size} for 2)") if args.size < 1
    
      provider = args[0]  
      data     = ( args.size > 1 ? args[1] : {} )
      options  = ( args.size > 2 ? args[2] : {} )
      
      module_name = parent_module_name
      contexts    = [ :data, :render, "template_#{provider}" ]
    
      default_options = {
        :node            => CORL::Provisioner::Puppetnode.node,
        :provisioner     => :puppetnode,
        :hiera_scope     => self,
        :puppet_scope    => self,
        :search          => 'core::default',
        :force           => true,
        :merge           => true,
        :undefined_value => :undef
      }
      
      if module_name
        config = CORL::Config.init(options, contexts, module_name, default_options)  
      else
        config = CORL::Config.init_flat(options, contexts, default_options)
      end
      
      template = CORL.template(config, provider)
      value    = template.render(data)
      
      CORL.remove_plugin(template)
      
      if config.get(:debug, false)      
        CORL.ui.info("\n", { :prefix => false })
        CORL.ui_group(CORL::Util::Console.cyan("#{provider} template")) do |ui|
          ui.info("-----------------------------------------------------")
        
          source_dump  = CORL::Util::Console.blue(CORL::Util::Data.to_json(data, true))
          value_render = CORL::Util::Console.green(value)       
        
          ui.info("Data:\n#{source_dump}")
          ui.info("Rendered:\n#{value_render}")
          ui.info("\n", { :prefix => false }) 
        end
      end
    end
    return value
  end
end

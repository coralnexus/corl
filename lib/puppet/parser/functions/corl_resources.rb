#
# corl_resources.rb
#
# This function adds resource definitions of a specific type to the Puppet catalog
# - Requires
# - -> Puppet resource definition name (define)
# - -> Hiera lookup name (full name)
# - Optional
# - -> default values for new resources
# If no resources are found, it returns without creating anything.
#
module Puppet::Parser::Functions  
  newfunction(:corl_resources, :doc => <<-EOS
This function adds resource definitions of a specific type to the Puppet catalog
- Requires
- -> Puppet resource definition name (define)
- -> Hiera lookup name (full name)
- Optional
- -> default values for new resources
If no resources are found, it returns without creating anything.
    EOS
) do |args|
    
    CORL.run do
      raise(Puppet::ParseError, "corl_resources(): Define at least the resource type and optional variable name " +
        "given (#{args.size} for 1)") if args.size < 1
      
      definition_name = args[0]
      type_name       = definition_name.sub(/^\@?\@/, '')
      
      resources       = ( args[1] ? args[1] : definition_name )
      defaults        = ( args[2] ? args[2] : {} )    
      
      tag             = ( args[3] ? args[3] : '' )
      tag_var         = tag.empty? ? '' : tag.gsub(/\_/, '::')
      override_var    = tag_var.empty? ? nil : "#{tag_var}::#{type_name}"
      default_var     = tag_var.empty? ? nil : "#{tag_var}::#{type_name}_defaults"
      
      options         = ( args[4] ? args[4] : {} )
      
      module_name     = parent_module_name
      contexts        = [ :resource ]
      
      default_options = {
        :provisioner  => :puppetnode,
        :hiera_scope  => self,
        :puppet_scope => self,
        :search       => 'core::default',
        :force        => true,
        :merge        => true
      }      
      unless tag.empty?
        default_options[:tag]             = tag
        default_options[:resource_prefix] = tag
        default_options[:title_prefix]    = tag
      end
      
      if module_name
        config = CORL::Config.init(options, contexts, module_name, default_options)  
      else
        config = CORL::Config.init_flat(options, contexts, default_options)
      end
      
      resources = CORL::Config.normalize(resources, override_var, config)
      defaults  = CORL::Config.normalize(defaults, default_var, config)
      
      CORL::Util::Puppet.add(definition_name, resources, defaults, config)
    end
  end
end

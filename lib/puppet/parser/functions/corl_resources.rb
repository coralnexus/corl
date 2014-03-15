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

      config = CORL::Config.init_flat(options, [ :resource, :corl_resources ], {
        :provisioner     => :puppetnode,
        :hiera_scope     => self,
        :puppet_scope    => self,
        :search          => 'core::default',
        :force           => true,
        :merge           => true,
        :resource_prefix => tag,
        :title_prefix    => tag
      })
      
      resources = CORL::Config.normalize(resources, override_var, config)
      defaults  = CORL::Config.normalize(defaults, default_var, config)
      
      dbg(resources, definition_name)
      dbg(defaults, 'defaults')    
      CORL::Util::Puppet.add(definition_name, resources, defaults, config)
    end
  end
end
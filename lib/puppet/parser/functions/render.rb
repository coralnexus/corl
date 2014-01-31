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
    Coral.run do
      raise(Puppet::ParseError, "render(): Must have a template class name and an optional source value specified; " +
        "given (#{args.size} for 2)") if args.size < 1
    
      class_name = args[0]  
      data       = ( args.size > 1 ? args[1] : {} )
      options    = ( args.size > 2 ? args[2] : {} )
    
      config = Coral::Config.init_flat(options, [ :data, :render ], {
        :hiera_scope  => self,
        :puppet_scope => self,
        :search       => 'core::default',
        :init_fact    => 'hiera_ready',
        :force        => true,
        :merge        => true
      })
      value = Coral.template(class_name, config).render(data)
    end
    return value
  end
end
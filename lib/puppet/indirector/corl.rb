
require 'puppet/indirector/terminus'

class Puppet::Indirector::Corl < Puppet::Indirector::Terminus
  
  def initialize(*args)
    unless CORL::Config.config_initialized?
      raise "CORL terminus not supported without the CORL library"
    end
    super
  end
  
  #---

  def find(request)
    puppet_scope = request.options[:variables]    
    module_name  = nil
    module_name  = puppet_scope.source.module_name if puppet_scope.source
    contexts     = [ :param, :data_binding, request.key ]
    
    default_options = {
      :provisioner     => :puppetnode,
      :hiera_scope     => puppet_scope,
      :puppet_scope    => puppet_scope,
      :search          => 'core::default',
      :search_name     => false,
      :force           => true,
      :merge           => true,
      :undefined_value => :undef
    }
    
    if module_name
      config = CORL::Config.init({}, contexts, module_name, default_options)  
    else
      config = CORL::Config.init_flat({}, contexts, default_options)
    end
          
    value = CORL::Config.lookup(request.key, nil, config)
  end
end

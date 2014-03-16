
require 'puppet/indirector/terminus'

class Puppet::Indirector::CORL < Puppet::Indirector::Terminus
  
  def initialize(*args)
    unless CORL::Config.initialized?
      raise "CORL terminus not supported without the CORL library"
    end
    super
  end
  
  #---

  def find(request)
    config = CORL::Config.init_flat({}, [ :param, :data_binding ], {
      :provisioner  => :puppetnode,
      :hiera_scope  => request.options[:variables],
      :puppet_scope => request.options[:variables],
      :search       => 'core::default',
      :search_name  => false,
      :force        => true,
      :merge        => true
    })    
    value = CORL::Config.lookup(request.key, nil, config)
  end
end

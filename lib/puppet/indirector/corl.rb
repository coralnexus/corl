
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
    config = CORL::Config.init({}, [ :all, :param, :data_binding ], {
      :hiera_scope  => request.options[:variables],
      :puppet_scope => request.options[:variables],
      :search       => 'core::default',
      :search_name  => false,
      :init_fact    => 'corl_config_ready',
      :force        => true,
      :merge        => true
    })    
    value = CORL::Config.lookup(request.key, nil, config)
  end
end

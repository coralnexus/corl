
require 'puppet/indirector/terminus'

class Puppet::Indirector::Coral < Puppet::Indirector::Terminus
  
  def initialize(*args)
    unless Coral::Config.initialized?
      #raise "Coral terminus not supported without the Coral library"
    end
    super
  end
  
  #---

  def find(request)
    config = Coral::Config.init({}, [ :all, :param, :data_binding ], {
      :hiera_scope  => request.options[:variables],
      :puppet_scope => request.options[:variables],
      :search       => 'core::default',
      :search_name  => false,
      :init_fact    => 'hiera_ready',
      :force        => true,
      :merge        => true
    })    
    value = Coral::Config.lookup(request.key, nil, config)
  end
end

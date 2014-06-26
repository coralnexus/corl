
module CORL
module Plugin
class Builder < CORL.plugin_class(:nucleon, :base)
  
  include Parallel
  
  extend Mixin::Builder::Global
  include Mixin::Builder::Instance
  
  #-----------------------------------------------------------------------------
  # Builder plugin interface
  
  def normalize(reload)
    super
    yield if block_given?
  end
  
  #-----------------------------------------------------------------------------
  # Checks

  #-----------------------------------------------------------------------------
  # Property accessors / modifiers

  network_settings :builder
  
  #-----------------------------------------------------------------------------
  # Builder operations
 
  def build(node, options = {})
    config        = Config.ensure(options)    
    environment   = Util::Data.ensure_value(config[:environment], node.lookup(:corl_environment))
    configuration = process_environment(export, environment)    
    
    FileUtils.mkdir_p(build_directory)
    
    status = parallel(:build_provider, configuration, environment)
    status.values.include?(false) ? false : true
  end
  
  #---
  
  def build_provider(name, project_reference, environment)
    # Implement in sub classes
    true
  end
end
end
end

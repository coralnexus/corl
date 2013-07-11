
module Coral
module Mixins
module ConfigOps
  #-----------------------------------------------------------------------------
  # Parsing
      
  def parse(statement, options = {})
    config = Config.ensure(options)
    
    # statement = 'common->php::apache::memory_limit = 32M'
    # statement = 'identity -> test -> users::user[admin][shell]'
    # statement = 'servers->development->dev.loc->facts[server_environment]=vagrant'
    # statement = 'cloud->settings[debug][puppet][options] = ["--debug"]'
    
    reference, new_value = statement.split(/\=/)
    new_value            = new_value.join('=').strip if new_value && new_value.is_a?(Array)
    
    config_elements = reference.gsub(/\s+/, '').split(/\-\>/)
    property        = config_elements.pop
    config_file     = config_elements.pop
    
    if config_directory = config.get(:directory, nil)
      config_path = File.join(repo.directory, config_directory, *config_elements)
    else
      config_path = File.join(repo.directory, *config_elements)
    end
    
    return nil unless property && config_file
    
    config_file = "#{config_file}." + config.get(:ext, 'json')
    property    = property.gsub(/\]$/, '').split(/\]?\[/)
    data        = open(config_path, config_file, config)
       
    return { 
      :path          => config_path, 
      :file          => config_file, 
      :property      => property,
      :conf          => data,
      :current_value => (data ? data.get(property) : nil), 
      :new_value     => eval(new_value) 
    }    
  end
end
end
end
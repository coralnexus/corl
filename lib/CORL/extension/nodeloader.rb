
module CORL
module Extension
class Nodeloader < CORL.plugin_class(:extension)

  def configuration_file_base(config)
    plugin = config[:plugin]
    dbg(plugin, 'plugin')
    
  end   
end
end
end
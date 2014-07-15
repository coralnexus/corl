
module Nucleon
module Extension
class CorlConfig < CORL.plugin_class(:nucleon, :extension)
  
  def configuration_file_base(config)
    plugin      = config[:plugin]
    file_bases  = [ :build, :vagrant] 
    translators = Nucleon.loaded_plugins(:nucleon, :translator).keys
    
    Dir.glob(File.join(plugin.directory, '*.*')).each do |file|
      file_ext = File.extname(file)
      
      if translators.include?(file_ext.sub('.', '').to_sym)
        file_base = File.basename(file).gsub(/#{file_ext}$/, '').to_sym
        
        unless file_base == :corl || file_bases.include?(file_base)
          file_bases << file_base
        end
      end
    end
    file_bases
  end
end
end
end

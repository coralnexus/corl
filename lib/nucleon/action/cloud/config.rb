
module Nucleon
module Action
module Cloud
class Config < CORL.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:cloud, :config, 949)
  end
 
  #-----------------------------------------------------------------------------
  # Settings
 
  def configure
    super do
      codes :configuration_parse_failed,
            :configuration_save_failed,
            :configuration_delete_failed
      
      register_str :name
      register_array :value
      
      register_bool :array      
      register_bool :delete
      register_bool :append
      
      register_translator :input_format
      register_translator :format, :json
    end
  end
  
  #---
  
  def ignore
    node_ignore
  end
  
  def arguments
    [ :name, :value ]
  end
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node|
      ensure_network do
        config_info = parse_config_reference(node, settings[:name])
        
        unless config_info
          myself.status = code.configuration_parse_failed
        end
        
        if config_info[:property].nil?
          render_config_properties(config_info)
           
        elsif settings.delete(:delete, false)
          delete_config_property(config_info)
                          
        elsif ! settings[:value].empty?
          set_config_property(config_info, settings[:value])
        else
          render_config_property(config_info)
        end
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Sub operations
  
  def render_config_properties(config_info)
    if file_labels = config_info[:rendered_files]
      info('subconfigurations', { :prefix => false })
      info("\n", { :i18n => false })
      file_labels.each do |label|
        prefixed_message(:info, '  ', label, { :i18n => false, :prefix => false })
      end
      info("\n", { :i18n => false })  
    else
      format        = settings[:format]
      myself.result = config_info[:config].export
      render result, :format => format
    end  
  end
  
  #---
  
  def render_config_property(config_info)
    format        = settings[:format]
    myself.result = config_info[:value]
    render result, :format => format 
  end
  
  #---
  
  def delete_config_property(config_info)
    name        = parse_property_name(config_info[:property])    
    remote_text = remote_message(settings[:net_remote])
    config_file = config_info[:file].sub(network.directory + File::SEPARATOR, '')
    
    render_options = { :config_file => blue(config_file), :name => blue(name), :remote_text => yellow(remote_text) }
    
    config_info[:config].delete(config_info[:property])
    
    if File.exists?(config_info[:file])    
      if Util::Disk.write(config_info[:file], config_info[:translator].generate(config_info[:config].export))
        if network.save({ :files => config_file, :remote => settings[:net_remote], :message => "Deleting configuration #{name} from #{config_file}", :allow_empty => true })
          success('delete', render_options)
        else
          error('delete', render_options)
          myself.status = code.configuration_save_failed    
        end
      else
        error('file_save', render_options)
        myself.status = code.configuration_save_failed  
      end
    else
      info('no_config_file', render_options)    
    end
  end
  
  #---
  
  def set_config_property(config_info, values)
    name        = parse_property_name(config_info[:property])    
    remote_text = remote_message(settings[:net_remote])
    config_file = config_info[:file].sub(network.directory + File::SEPARATOR, '')
    
    render_options = { :config_file => blue(config_file), :name => blue(name), :remote_text => yellow(remote_text) }
    
    config_file  = config_info[:file].sub(network.directory + File::SEPARATOR, '')
    input_format = settings[:input_format]
    
    values.each_with_index do |value, index|    
      values[index] = render(value, { 
        :format => input_format, 
        :silent => true 
      }) if input_format
      values[index] = Util::Data.value(values[index])
    end
    
    if settings[:append]
      if prev_value = config_info[:value]
        prev_value = array(prev_value)
        
        values.each do |value|
          prev_value.push(value)
        end        
        values = prev_value
      end
    else
      if settings[:array]
        values = array(values)
      elsif values.size == 1
        values = values[0]
      end    
    end
            
    myself.result = values    
    config_info[:config].set(config_info[:property], result)
    
    FileUtils.mkdir_p(File.dirname(config_info[:file]))
    
    if Util::Disk.write(config_info[:file], config_info[:translator].generate(config_info[:config].export))
      if network.save({ :files => config_file, :remote => settings[:net_remote], :message => "Updating configuration #{name} in #{config_file}", :allow_empty => true })
        success('update', render_options)
      else
        error('update', render_options)
        myself.status = code.configuration_save_failed    
      end
    else
      error('file_save', render_options)
      myself.status = code.configuration_save_failed  
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def parse_config_reference(node, name)
    info        = {}
    data        = {}
    config      = CORL::Config.new({}, {}, true, false)    
    translators = CORL.loaded_plugins(:nucleon, :translator).keys
    
    # common@php::apache::memory_limit
    # identity/test@users::user[admin][shell]
    # servers/development/dev.loc@facts[server_environment]
    
    config_elements  = name.split('@')
    
    property         = config_elements.size > 1 ? config_elements.pop : nil
    config_elements  = config_elements[0].split('/') if config_elements.size > 0   
    config_file_name = config_elements.pop    
    config_path      = File.join(network.config_directory, *config_elements)
    config_dir       = config_file_name ? File.join(config_path, config_file_name) : config_path
    config_file      = nil
    config_files     = nil
    translator       = []
          
    if config_file_name
      property = property.gsub(/\]$/, '').split(/\]?\[/) if property
        
      translators.each do |translator_name|
        config_file = File.join(config_path, "#{config_file_name}." + translator_name.to_s)
        
        if File.exists?(config_file)
          unless data = Util::Disk.read(config_file)
            error('file_read', { :config_file => config_file })
            return nil
          end
          unless load_translator = CORL.translator({}, translator_name)
            error('translator_load', { :translator => translator_name })
            return nil
          end    
          config.import(load_translator.parse(data))
          translator << load_translator
        end
      end
    end
    
    if translator.empty?
      translator  = nil
      config_file = nil
    else
      translator  = translator.size > 1 ? translator.shift : translator[0]
      config_file = File.join(config_path, "#{config_file_name}." + translator.plugin_name.to_s)
    end
      
    unless config_file
      hiera_search_path = node.hiera_configuration[:hierarchy]
      config_files      = []
      
      if File.directory?(config_dir)
        config_files = Dir.glob("#{config_dir}/**/*").select do |file|
          is_config = false
          
          translators.each do |translator_name|
            is_config = true if file.match(/\.#{translator_name}/)
          end
          is_config
        end
      
        config_files.collect! do |file|
          file.sub(/#{network.config_directory + File::SEPARATOR}/, '')
        end
      end
      
      ordered_config_files  = []
      rendered_config_files = []
      
      hiera_search_path.each do |search_path|
        search_components = search_path.split(File::SEPARATOR)
        
        rendered_config_files << "SEARCH: #{search_path}"
         
        config_files.each do |file|
          file_ext                 = File.extname(file)
          file_components          = file.sub(/\..*$/, '').split(File::SEPARATOR)
          rendered_file_components = []
          file_match               = true
          
          search_components.each_with_index do |search_item, index|
            if search_item.strip =~ /^%{:?:?([^}]+)}$/ && index < file_components.size
              rendered_file_components << cyan(file_components[index])
            elsif search_item != file_components[index]
              file_match = false
            else
              rendered_file_components << yellow(search_item)
            end
          end
          
          rendered_file = "        #{rendered_file_components.join(File::SEPARATOR)} [ #{blue(file_ext.sub('.', ''))} ]"
          
          if file_match && ! ordered_config_files.include?(file)
            ordered_config_files << file
            rendered_config_files << rendered_file
          end
        end
      end
    end
      
    {
      :translator     => translator,
      :file           => config_file,
      :files          => ordered_config_files,
      :rendered_files => rendered_config_files,
      :property       => property,
      :config         => config,
      :value          => property ? Util::Data.value(config.get(property)) : nil
    }
  end
end
end
end
end

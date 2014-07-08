
module Nucleon
module Action
module Cloud
class Config < CORL.plugin_class(:nucleon, :cloud_action)
  
  include Mixin::Action::Registration
  
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
      
      register_str :name, nil
      register_array :value
      
      register_bool :delete
      register_bool :append
      
      register_translator :input_format
      register_translator :load_format, :json 
      register_translator :format, :json
    end
  end
  
  #---
   
  def arguments
    [ :name, :value ]
  end
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      ensure_network(network) do
        config_info = parse_config_reference(network, settings[:name])
        
        unless config_info
          myself.status = code.configuration_parse_failed
        end
        
        if config_info[:property].nil?
          render_config_properties(network, config_info)  
        elsif settings.delete(:delete, false)
          delete_config_property(network, config_info, sanitize_remote(network, settings[:net_remote]))                
        elsif ! settings[:value].empty?
          set_config_property(network, config_info, settings[:value], settings[:append], sanitize_remote(network, settings[:net_remote]))
        else
          render_config_property(network, config_info)
        end
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Sub operations
  
  def render_config_properties(network, config_info)
    if file_labels = config_info[:files]
      info("Sub configurations available:", { :i18n => false })
      file_labels.each do |label|
        info("-> #{yellow(label)}", { :i18n => false })
      end  
    else
      format        = settings[:format]
      myself.result = config_info[:config].export
      render result, :format => format
    end  
  end
  
  #---
  
  def render_config_property(network, config_info)
    format        = settings[:format]
    myself.result = config_info[:value]
    render result, :format => format 
  end
  
  #---
  
  def delete_config_property(network, config_info, remote = nil)
    name        = parse_property_name(config_info[:property])    
    remote_text = remote_message(remote)
    config_file = config_info[:file].sub(network.directory + File::SEPARATOR, '')
    
    config_info[:config].delete(config_info[:property])
    
    if File.exists?(config_info[:file])    
      if Util::Disk.write(config_info[:file], config_info[:translator].generate(config_info[:config].export))
        if network.save({ :files => config_file, :remote => remote, :message => "Deleting configuration #{name} from #{config_file}", :allow_empty => true })
          success("Configuration `#{blue(name)}` deleted (#{yellow(remote_text)})", { :i18n => false })
        else
          error("Configuration `#{blue(name)}` deletion could not be saved", { :i18n => false })
          myself.status = code.configuration_save_failed    
        end
      else
        error("Configuration file `#{blue(config_file)}` could not be saved", { :i18n => false })
        myself.status = code.configuration_save_failed  
      end
    else
      info("Configuration file `#{blue(config_file)} does not exist so configuration can not be deleted", { :i18n => false })    
    end
  end
  
  #---
  
  def set_config_property(network, config_info, values, append = false, remote = nil)
    name         = parse_property_name(config_info[:property])    
    remote_text  = remote_message(remote)
    
    config_file  = config_info[:file].sub(network.directory + File::SEPARATOR, '')
    input_format = settings[:input_format]
    
    values.each_with_index do |value, index|    
      values[index] = render(value, { 
        :format => input_format, 
        :silent => true 
      }) if input_format
      values[index] = Util::Data.value(values[index])
    end
    
    if append
      if prev_value = config_info[:value]
        prev_value = array(prev_value)
        
        values.each do |value|
          prev_value.push(value)
        end        
        values = prev_value
      end
    else
      if values.size == 1
        values = values[0]
      end    
    end
            
    myself.result = values    
    config_info[:config].set(config_info[:property], result)
    
    FileUtils.mkdir_p(File.dirname(config_info[:file]))
    
    if Util::Disk.write(config_info[:file], config_info[:translator].generate(config_info[:config].export))
      if network.save({ :files => config_file, :remote => remote, :message => "Updating configuration #{name} in #{config_file}", :allow_empty => true })
        success("Configuration `#{blue(name)}` update (#{yellow(remote_text)})", { :i18n => false })
      else
        error("Configuration `#{blue(name)}` update could not be saved", { :i18n => false })
        myself.status = code.configuration_save_failed    
      end
    else
      error("Configuration file `#{blue(config_file)}` could not be saved", { :i18n => false })
      myself.status = code.configuration_save_failed  
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def parse_config_reference(network, name)
    info = {}
    data = {}
    
    translators = CORL.loaded_plugins(:nucleon, :translator).keys
    
    # common@php::apache::memory_limit
    # identity/test@users::user[admin][shell]
    # servers/development/dev.loc@facts[server_environment]
    
    config_elements  = name.split('@')
    
    property         = config_elements.size > 1 ? config_elements.pop : nil
    config_elements  = config_elements[0].split('/')    
    config_file_name = config_elements.pop    
    config_path      = File.join(network.config_directory, *config_elements)
        
    if config_file_name
      config_dir   = File.join(config_path, config_file_name)
      config_file  = File.join(config_path, "#{config_file_name}." + settings[:load_format].to_s)
      config_files = nil
      property     = property.gsub(/\]$/, '').split(/\]?\[/) if property
      
      unless translator = CORL.translator({}, settings[:load_format])
        error("Translator for #{settings[:format]} could not be loaded", { :i18n => false })
        return nil
      end
      
      if File.exists?(config_file)
        unless data = Util::Disk.read(config_file)
          error("Failed to read file: #{config_file}", { :i18n => false })
          return nil
        end
        config = CORL::Config.new(translator.parse(data))
      elsif File.directory?(config_dir)
        config_files = Dir.glob("#{config_dir}/**/*").select do |file|
          is_config = false
          
          translators.each do |translator_name|
            is_config = true if file.match(/\.#{translator_name}/)
          end
          is_config
        end
        config_files.each_with_index do |file, index|
          config_files[index] = file.sub(/#{network.config_directory + File::SEPARATOR}/, '')
          config_files[index] = config_files[index].sub(/\.([a-z0-9]+)$/, ' [ ' + blue('\1') + ' ]') 
        end
      end
      
      config = CORL::Config.new unless config            
      info   = {
        :translator => translator,
        :file       => config_file,
        :files      => config_files,
        :property   => property,
        :config     => config,
        :value      => property ? Util::Data.value(config.get(property)) : nil
      }
    end
    info
  end
  
  #---

  def parse_property_name(property)
    property = property.clone
    
    if property.size > 1
      property.shift.to_s + '[' + property.join('][') + ']'
    else
      property.shift.to_s
    end
  end
  
  #---
  
  def remote_message(remote)
    remote ? "#{remote}" : "LOCAL ONLY"
  end
end
end
end
end

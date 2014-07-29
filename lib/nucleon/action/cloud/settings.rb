
module Nucleon
module Action
module Cloud
class Settings < Nucleon.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:cloud, :settings, 950)
  end
 
  #-----------------------------------------------------------------------------
  # Settings
 
  def configure
    super do
      codes :settings_save_failed,
            :settings_delete_failed
      
      register_str :group
      register_str :name
      register_array :value
      
      register_bool :array
      register_bool :delete
      register_bool :append
      register_bool :groups
      
      register_translator :input_format
      register_translator :format, :json
    end
  end
  
  #---
  
  def ignore
    node_ignore
  end
   
  def arguments
    [ :group, :name, :value ]
  end
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node|
      ensure_network do
        if settings[:groups]
          render_groups
          
        elsif settings[:group].empty?
          render_settings
          
        elsif settings[:name].empty?
          render_settings(settings[:group])
          
        else
          name = settings[:name].gsub(/\]$/, '').split(/\]?\[/)
          
          if settings.get(:delete, false)
            delete_settings(name)
                 
          elsif ! settings[:value].empty?
            set_settings(name, settings[:value])
                
          else
            render_settings([ settings[:group], name ])  
          end          
        end
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Settings operations
  
  def render_groups
    groups = network.config.get(:settings).keys
    
    info('groups')
    groups.each do |group|
      info("-> #{green(group)}", { :i18n => false })
    end
  end
  
  #---
  
  def render_settings(elements = [])
    format = settings[:format]
    
    if elements.size > 0
      myself.result = network.config.get([ :settings, elements ])
    else
      myself.result = network.config.get(:settings)
    end
    render result, :format => format  
  end
   
  #---
  
  def delete_settings(property)
    group       = settings[:group]
    name        = parse_property_name(property)    
    remote_text = remote_message(settings[:net_remote])
    
    render_options = { :group => blue(group), :name => blue(name), :remote_text => yellow(remote_text) }
    
    network.config.delete([ :settings, group, property ])
    
    if network.save({ :remote => settings[:net_remote], :message => "Deleting #{group} setting #{name}", :allow_empty => true })
      success('delete', render_options)
    else
      error('delete', render_options)
      myself.status = code.settings_delete_failed    
    end
  end
  
  #---
  
  def set_settings(property, values)
    group        = settings[:group]
    name         = parse_property_name(property)    
    remote_text  = remote_message(settings[:net_remote])
    
    render_options = { :group => blue(group), :name => blue(name), :remote_text => yellow(remote_text) }
    
    input_format = settings[:input_format]
    
    values.each_with_index do |value, index|    
      values[index] = render(value, { 
        :format => input_format, 
        :silent => true 
      }) if input_format
      values[index] = Util::Data.value(values[index])
    end
    
    if settings[:append]
      if prev_value = network.config.get([ :settings, group, property ])
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
    network.config.set([ :settings, group, property ], result)
    
    if network.save({ :remote => settings[:net_remote], :message => "Updating #{group} setting #{name}", :allow_empty => true })
      success('update', render_options)
    else
      error('update', render_options)
      myself.status = code.settings_save_failed    
    end
  end
end
end
end
end

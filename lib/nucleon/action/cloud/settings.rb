
module Nucleon
module Action
module Cloud
class Settings < CORL.plugin_class(:nucleon, :cloud_action)
  
  include Mixin::Action::Registration
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:cloud, :settings, 951)
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
      
      register_bool :delete
      register_bool :append
      register_bool :groups
      
      register_translator :input_format
      register_translator :format, :json
    end
  end
  
  #---
  
  def ignore
    [ :nodes ]
  end
   
  def arguments
    [ :group, :name, :value ]
  end
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      ensure_network(network) do
        if settings[:groups]
          render_groups(network)
          
        elsif settings[:group].empty?
          render_settings(network)
          
        elsif settings[:name].empty?
          render_settings(network, settings[:group])
          
        else
          name = settings[:name].gsub(/\]$/, '').split(/\]?\[/)
          
          if settings.get(:delete, false)
            delete_settings(network, name, sanitize_remote(network, settings[:net_remote]))
                 
          elsif ! settings[:value].empty?
            set_settings(network, name, settings[:value], sanitize_remote(network, settings[:net_remote]))
                
          else
            render_settings(network, [ settings[:group], name ])  
          end          
        end
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Sub operations
  
  def render_groups(network)
    groups = network.config.get(:settings).keys
    
    info("Currently defined groups:", { :i18n => false })
    groups.each do |group|
      info("-> #{green(group)}", { :i18n => false })
    end
  end
  
  #---
  
  def render_settings(network, elements = [])
    format = settings[:format]
    
    if elements.size > 0
      myself.result = network.config.get([ :settings, elements ])
    else
      myself.result = network.config.get(:settings)
    end
    render result, :format => format  
  end
   
  #---
  
  def delete_settings(network, property, remote = nil)
    group       = settings[:group]
    name        = parse_property_name(property)    
    remote_text = remote_message(remote)
    
    network.config.delete([ :settings, group, property ])
    
    if network.save({ :remote => remote, :message => "Deleting #{group} setting #{name}", :allow_empty => true })
      success("Group #{blue(group)} setting `#{blue(name)}` deleted (#{yellow(remote_text)})", { :i18n => false })
    else
      error("Group #{blue(group)} setting `#{blue(name)}` deletion could not be saved", { :i18n => false })
      myself.status = code.settings_delete_failed    
    end
  end
  
  #---
  
  def set_settings(network, property, values, remote = nil)
    group        = settings[:group]
    name         = parse_property_name(property)    
    remote_text  = remote_message(remote)
    
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
      if values.size == 1
        values = values[0]
      end    
    end
            
    myself.result = values    
    network.config.set([ :settings, group, property ], result)
    
    if network.save({ :remote => remote, :message => "Updating #{group} setting #{name}", :allow_empty => true })
      success("Group #{blue(group)} setting `#{blue(name)}` updated (#{yellow(remote_text)})", { :i18n => false })
    else
      error("Group #{blue(group)} setting `#{blue(name)}` update could not be saved", { :i18n => false })
      myself.status = code.settings_save_failed    
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities

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

module Nucleon
module Action
module Node
class Cache < CORL.plugin_class(:nucleon, :cloud_action)
  
  include Mixin::Action::Registration
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :cache, 600)
  end
  
  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      codes :cache_save_failed
      
      register_str :name
      register_str :value
      
      register_bool :delete
      register_bool :clear     
      
      register_translator :input_format            
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
      ensure_node(node) do
        if settings.delete(:clear, false)
          clear_node_cache(node)
        elsif ! settings[:name] || settings[:name].empty?
          render_node_cache(node)
        else
          settings[:name]  = settings[:name].split('.')
          settings[:value] = nil if settings[:value].is_a?(String) && settings[:value].empty? 
          
          if settings.delete(:delete, false)
            delete_node_cache(node, settings[:name])                
          elsif ! settings[:value].nil?
            set_node_cache(node, settings[:name], settings[:value])
          else
            render_node_cache_property(node, settings[:name])
          end
        end
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Sub operations
  
  def render_node_cache(node)
    format        = settings[:format]
    myself.result = node.cache_setting([], {}, :hash)
    render result, :format => format  
  end
  
  #---
  
  def render_node_cache_property(node, name)
    format        = settings[:format]
    myself.result = node.cache_setting(name)
    render result, :format => format 
  end
  
  #---
  
  def delete_node_cache(node, name)
    node.delete_cache_setting(name)
    
    if node.cache.status == code.success
      success("Cached property #{name.join('.')} deleted", { :i18n => false })
    else
      error("Cached property #{name.join('.')} deletion could not be saved", { :i18n => false })
      myself.status = code.cache_save_failed  
    end  
  end
  
  #---
  
  def set_node_cache(node, name, value)
    input_format = settings[:input_format]
    
    value        = Util::Data.value(render(value, { 
      :format => input_format, 
      :silent => true 
    })) if input_format
            
    myself.result = value
        
    node.set_cache_setting(name, value)
    
    if node.cache.status == code.success  
      success("Cached property #{name.join('.')} saved", { :i18n => false })
    else
      error("Cached property #{name.join('.')} could not be saved", { :i18n => false })
      myself.status = code.cache_save_failed  
    end  
  end
  
  #---
  
  def clear_node_cache(node)
    node.clear_cache
    
    if node.cache.status == code.success
      success("Cached properties cleared", { :i18n => false })
    else
      error("Cached properties could not be cleared", { :i18n => false })
      myself.status = code.cache_save_failed  
    end  
  end
end
end
end
end

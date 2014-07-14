
module Nucleon
module Action
module Node
class Fact < CORL.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe(action = :fact, weight = 570)
    describe_base(:node, action, weight, nil, nil, :node_fact)
  end
  
  #-----------------------------------------------------------------------------
  # Settings

  def configure(aggregate = false)
    super() do
      codes :fact_save_failed
      
      unless aggregate
        register_str :name, nil
        register_str :value
      
        register_bool :delete      
      
        register_translator :input_format
      end
      
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
    super do |node|
      ensure_node(node) do
        if ! settings[:name] || settings[:name].empty?
          render_node_facts(node)
        else
          if settings.delete(:delete, false)
            delete_node_fact(node, settings[:name], sanitize_remote(network, settings[:net_remote]))                
          elsif settings[:value] && ! settings[:value].empty?
            set_node_fact(node, settings[:name], settings[:value], sanitize_remote(network, settings[:net_remote]))
          else
            render_node_fact(node, settings[:name])
          end
        end
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Sub operations
  
  def render_node_facts(node)
    format        = settings[:format]
    myself.result = node.facts        
    render result, :format => format  
  end
  
  #---
  
  def render_node_fact(node, name)
    format        = settings[:format]
    myself.result = node.fact(name)    
    render result, :format => format 
  end
  
  #---
  
  def delete_node_fact(node, name, remote = nil)
    remote_text = remote ? "#{remote}" : "LOCAL ONLY"
    
    node.delete_facts(name)
            
    if node.save({ :remote => remote, :message => "Deleting fact #{name} from #{node.plugin_provider} #{node.plugin_name}" })
      success("Fact #{name} deleted (#{remote_text})", { :i18n => false })
    else
      error("Fact #{name} deletion could not be saved", { :i18n => false })
      myself.status = code.fact_save_failed  
    end  
  end
  
  #---
  
  def set_node_fact(node, name, value, remote = nil)
    remote_text  = remote ? "#{remote}" : "LOCAL ONLY"
    input_format = settings[:input_format]
    
    value        = Util::Data.value(render(value, { 
      :format => input_format, 
      :silent => true 
    })) if input_format
            
    myself.result = value           
    node.create_facts({ name => value })    
            
    if node.save({ :remote => remote, :message => "Saving fact #{name} to #{node.plugin_provider} #{node.plugin_name}" })
      success("Fact #{name} saved (#{remote_text})", { :i18n => false })
    else
      error("New fact #{name} could not be saved", { :i18n => false })
      myself.status = code.fact_save_failed  
    end  
  end
  
  #-----------------------------------------------------------------------------
  # Output
  
  def render_provider
    :node_fact
  end
end
end
end
end


module Nucleon
module Action
module Node
class Group < Nucleon.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe(action = :group, weight = 670)
    describe_base(:node, action, weight, nil, nil, :node_group)
  end
  
  #-----------------------------------------------------------------------------
  # Settings

  def configure(aggregate = false)
    super() do
      codes :group_save_failed
      
      unless aggregate
        register_str :name, nil
        
        register_bool :add      
        register_bool :delete
      end
      
      register_translator :format, :json
    end
  end
  
  #---
  
  def arguments
    [ :name ]
  end

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node|
      ensure_node(node) do
        if ! settings[:name] || settings[:name].empty?
          render_node_groups(node)
        else
          if settings.delete(:delete, false)
            delete_node_group(node, settings[:name], sanitize_remote(network, settings[:net_remote]))                
          elsif settings.delete(:add, false)
            set_node_group(node, settings[:name], sanitize_remote(network, settings[:net_remote]))
          else
            render_node_group(node, settings[:name])
          end
        end
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Sub operations
  
  def render_node_groups(node)
    format        = settings[:format]
    myself.result = node.groups        
    render result, :format => format  
  end
  
  #---
  
  def render_node_group(node, name)
    if node.groups.include?(name.to_s)
      myself.result = true
      success("Group #{name} found", { :i18n => false })
    else
      myself.result = false
      warn("Group #{name} not found", { :i18n => false })
    end
  end
  
  #---
  
  def delete_node_group(node, name, remote = nil)
    remote_text = remote ? "#{remote}" : "LOCAL ONLY"
    
    node.remove_groups(name)
            
    if node.save({ :remote => remote, :message => "Deleting group #{name} from #{node.plugin_provider} #{node.plugin_name}" })
      success("Group #{name} deleted (#{remote_text})", { :i18n => false })
    else
      error("Group #{name} deletion could not be saved", { :i18n => false })
      myself.status = code.group_save_failed  
    end  
  end
  
  #---
  
  def set_node_group(node, name, remote = nil)
    remote_text  = remote ? "#{remote}" : "LOCAL ONLY"
            
    myself.result = name           
    node.add_groups(name)    
            
    if node.save({ :remote => remote, :message => "Saving group #{name} to #{node.plugin_provider} #{node.plugin_name}" })
      success("Group #{name} saved (#{remote_text})", { :i18n => false })
    else
      error("New group #{name} could not be saved", { :i18n => false })
      myself.status = code.group_save_failed  
    end  
  end
  
  #-----------------------------------------------------------------------------
  # Output
  
  def render_provider
    :node_group
  end
end
end
end
end

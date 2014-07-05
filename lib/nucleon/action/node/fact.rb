
module Nucleon
module Action
module Node
class Fact < CORL.plugin_class(:nucleon, :cloud_action)
  
  include Mixin::Action::Registration
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :fact, 570)
  end
  
  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      register_str :name
      register_str :value
      
      register_bool :delete      
      
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
        delete_setting = settings.delete(:delete, false)
        input_format   = settings.delete(:input_format)
        format         = settings.delete(:format)
        
        if settings[:name].empty?
          myself.result = node.facts        
          render result, :format => format
        else
          if delete_setting
            node.delete_facts(settings[:name])
            node.save(settings)
                
          elsif ! settings[:value].empty?
            settings[:value] = Util::Data.value(render(settings[:value], { 
              :format => input_format, 
              :silent => true 
            })) if input_format
            
            myself.result = settings[:value]           
            node.create_facts({ settings[:name] => result })
            node.save(settings)
              
          else
            myself.result = node.fact(settings[:name])
            render result, :format => format
          end
        end
      end
    end
  end
end
end
end
end

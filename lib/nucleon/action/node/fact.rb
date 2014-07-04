
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
      register :name, :str, ''
      register :value, :str, ''
      
      register :delete, :bool, false      
      
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
        input_translator  = CORL.translator({}, settings[:input_format]) if settings[:input_format]
        output_translator = CORL.translator({}, settings[:format])
        
        delete_setting = settings.delete(:delete, false)
        
        if settings[:name].empty?
          myself.result = node.facts        
          $stderr.puts output_translator.generate(result)
        else
          if delete_setting
            node.delete_fact(settings[:name])
                
          elsif ! settings[:value].empty?
            settings[:value] = Util::Data.value(input_translator.parse(settings[:value])) if settings[:input_format]
            
            dbg(settings[:value], 'value')
            myself.result    = settings[:value]           
            node.create_fact(settings[:name], result)
              
          else
            myself.result = node.fact(settings[:name])
            $stderr.puts output_translator.generate(result)
          end
        end
      end
    end
  end
end
end
end
end

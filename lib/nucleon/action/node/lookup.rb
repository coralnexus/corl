
module Nucleon
module Action
module Node
class Lookup < CORL.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :lookup, 565)
  end

  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      register :properties, :array, []
      register :context, :str, :priority do |value|
        success = true
        options = [ :priority, :array, :hash ]
        unless options.include?(value.to_sym)
          warn('corl.actions.lookup.errors.context', { :value => value, :options => options.join(', ') })
          success = false
        end
        success
      end
    end
  end
  
  #---
  
  def arguments
    [ :properties ]
  end

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      ensure_node(node) do
        if settings[:properties].empty?
          myself.result = node.hiera_configuration(node.facts)
          $stderr.puts Util::Data.to_json(result, true)
        else
          properties = {}
          
          settings.delete(:properties).each do |property|
            properties[property] = node.lookup(property, nil, settings)
          end
          $stderr.puts Util::Data.to_json(properties, true)
          myself.result = properties 
        end        
      end
    end
  end
end
end
end
end

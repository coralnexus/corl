
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
      register :property, :str, nil
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
    [ :property ]
  end

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      ensure_node(node) do
        property = settings.delete(:property)
        value    = node.lookup(property, nil, settings)
      
        ui.info(Util::Data.to_json(value, true), { :prefix => false })
        myself.result = value
      end
    end
  end
end
end
end
end

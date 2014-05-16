
module CORL
module Action
class Lookup < Plugin::CloudAction
 
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
        value    = lookup(property, nil, settings)
      
        ui.info(Util::Data.to_json(value, true), { :prefix => false })
        myself.result = value
      end
    end
  end
end
end
end

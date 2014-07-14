
module Nucleon
module Action
module Cloud
class Images < CORL.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:cloud, :images, 850)
  end

  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :node_load_failure,
            :image_load_failure
      
      register :region, :str, nil      
      register :match_case, :bool, false
      register :require_all, :bool, true
      register :search, :array, []
    end
  end
  
  #---
  
  def ignore
    node_ignore - [ :node_provider ]
  end
  
  def arguments
    [ :node_provider, :search ]
  end
  
  #-----------------------------------------------------------------------------
  # Operations
 
  def execute
    super do |local_node|
      info('corl.actions.images.start')
      
      ensure_network do
        if node = network.test_node(settings[:node_provider], { :region => settings[:region] })
          if images = node.images(settings[:search], settings)
            images.each do |image|
              info(node.render_image(image), { :prefix => false, :i18n => false })
            end
          
            myself.result = images
            success('corl.actions.images.results', { :images => images.length }) if images.length > 1
          else
            myself.status = code.image_load_failure
          end
        else
          myself.status = code.node_load_failure
        end
      end
    end
  end
end
end
end
end

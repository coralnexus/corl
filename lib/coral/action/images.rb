
module Coral
module Action
class Images < Plugin::Action

  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :node_load_failure,
            :image_load_failure
            
      register :match_case, :bool, false
      register :require_all, :bool, false
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
    super do |local_node, network|
      info('coral.actions.images.start')
      
      if node = network.test_node(settings[:node_provider])
        if images = node.images(settings[:search], settings)
          images.each do |image|
            render(node.render_image(image), { :prefix => false })
          end
          
          myself.result = images
          success('coral.actions.images.results', { :images => images.length }) if images.length > 1
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

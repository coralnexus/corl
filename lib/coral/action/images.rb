
module Coral
module Action
class Images < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Images action interface
  
  def normalize
    super('coral images <node_provider> [ <search_term> ... ]')
    
    codes :node_load_failure  => 20,
          :image_load_failure => 21
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.option_bool(:match_case, false, 
      [ '-c', '--match-case' ], 
      'coral.core.actions.images.options.match_case'
    )
    parser.option_bool(:require_all, false, 
      [ '-r', '--require-all' ], 
      'coral.core.actions.images.options.require_all'
    )
    parser.arg_str(:provider, nil, 
      'coral.core.actions.images.options.provider'
    )
    parser.arg_array(:search, [], 
      'coral.core.actions.images.options.search'
    )
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.images.start')
      
      if node = Coral.node(:test, {}, settings[:provider])
        if images = node.images(settings[:search], settings)
          images.each do |image|
            render(node.render_image(image), { :prefix => false })
          end
          success('coral.core.actions.images.results', { :images => images.length }) if images.length > 1
        else
          status = code.image_load_failure
        end
      else
        status = code.node_load_failure
      end
      status
    end
  end
end
end
end

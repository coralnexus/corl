
module VagrantPlugins
module CORL
module Action
class DeleteCache < BaseAction

  def call(env)
    super do
      @app.call env
      
      env[:ui].info I18n.t("corl.vagrant.actions.delete_cache.start")
      
      # Keep the box (in case we want to start from a saved image)
      box     = node.cache_setting(:box)
      box_url = node.cache_setting(:box_url)
      
      # Clear cache
      node.clear_cache
      
      if box && box_url
        # Re-add boxes if needed
        node.set_cache_setting(:box, box)
        node.set_cache_setting(:box_url, box_url)  
      end
    end
  end
end
end
end
end


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
      
      # Clear cache unless saved image
      node.clear_cache unless box && box_url
    end
  end
end
end
end
end

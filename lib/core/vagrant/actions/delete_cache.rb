
module VagrantPlugins
module CORL
module Action
class DeleteCache < BaseAction

  def call(env)
    super do
      @app.call env
      
      env[:ui].info I18n.t("corl.vagrant.actions.delete_cache.start")
      node.clear_cache
    end
  end
end
end
end
end


module VagrantPlugins
module CORL
module Action
class CreateShares < BaseAction

  def call(env)
    super do
      env[:ui].info I18n.t("corl.vagrant.actions.create_shares.start")
      
      vm.communicate.tap do |comm|
        # TODO: Figure out a better solution for remote network path.
        # Needs to work before facter and corl are installed
        # Local searches of remote configurations in the project perhaps?
        network_path = ::CORL::Config.fact(:corl_network)
        
        # Make sure the CORL network directory is properly set up
        # Vagrant root (project) directory is shared by default
        comm.sudo("rm -Rf #{network_path}")
        comm.sudo("ln -s /vagrant #{network_path}")
      end
      @app.call env
    end
  end
end
end
end
end


module CORL
module Extension
class Puppetloader < CORL.plugin_class(:extension)

  def register_plugins(config)
    connection  = Manager.connection
    provisioners = connection.plugins(:provisioner, :puppetnode)
    provisioner  = provisioners.empty? ? nil : provisioners[provisioners.keys.first]
  
    if provisioner
      # Register Puppet CORL extensions
      provisioner.env.modules.each do |mod|
        lib_dir = File.join(mod.path, 'lib', 'corl')
        if File.directory?(lib_dir)
          logger.debug("Registering Puppet module at #{lib_dir}")
          connection.register(lib_dir)
        end
      end
    end
  end      
end
end
end
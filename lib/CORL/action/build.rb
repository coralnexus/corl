
module CORL
module Action
class Build < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :network_failure
    end
  end
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      if network && node
        profiles     = array(node[:profiles])
        provisioners = {}
        
        # Compose needed provisioners and profiles
        profiles.each do |profile|
          info = Plugin::Provisioner.translate_reference(profile)
          
          if info
            provider = info[:provider]
            
            provisioners[provider] = { :profiles => [] } unless provisioners.has_key?(providers)
            provisioners[provider][:profiles] += info[:profiles]
          end
        end
                
        unless provisioners.empty?
          build_directory = File.join(network.directory, 'build')
          
          FileUtils.rm_rf(build_directory)
          FileUtils.mkdir(build_directory)
          
          provisioners.each do |provider, node_profiles|
            provider_build_directory = File.join(build_directory, provider)
            
            provisioners = node.provisioners(provider)
            
            if provisioners
              provisioners.each do |name, provisioner|
                dbg(name, 'name')
                dbg(provisioner, 'provisioner')
                #provisioner.build(provider_build_directory)
              end
            end
          end
        end        
      else
        myself.status = code.network_failure
      end
    end
  end
end
end
end


#
# Because we create configurations and operate on resulting machines during
# the course of a single CLI command run we need to be able to reload the 
# configurations based on updates to fetch Vagrant VMs and run Vagrant machine 
# actions.  TODO: Inquire about inclusion in Vagrant core?
#
module Vagrant
class Vagrantfile
  def reload
    @loader.clear_config_cache
    @config, _ = @loader.load(@keys)
  end
end

module Config
class Loader
  def clear_config_cache
    @config_cache = {}
  end    
end
end
end

#-------------------------------------------------------------------------------

module CORL
module Vagrant
module Config
  
  @@network = nil
  
  def self.network=network
    @@network = network
  end
  
  def self.network
    @@network
  end
  
  
  #
  # Gateway CORL configurator for Vagrant.
  #  
  def self.register(directory, config, &code)
    ::Vagrant.require_version ">= 1.5.0"
    
    config_network = network   
    config_network = load_network(directory) unless config_network
    
    if config_network
      # Vagrant settings
      unless configure_vagrant(config_network, config.vagrant)
        raise "Configuration of Vagrant general settings failed"
      end
      
      config_network.nodes(:vagrant, true).each do |node_name, node|
        config.vm.define node.id.to_sym do |machine|
          # VM settings
          unless configure_vm(node, machine)
            raise "Configuration of Vagrant VM failed: #{node_name}"
          end
          
          # SSH settings
          unless configure_ssh(node, machine)
            raise "Configuration of Vagrant VM SSH settings failed"
          end
          
          # Server shares
          unless configure_shares(node, machine)
            raise "Configuration of Vagrant shares failed: #{node_name}"
          end
          
          # Provisioner configuration
          unless configure_provisioner(network, node, machine)
            raise "Configuration of Vagrant provisioner failed: #{node_name}"
          end
          
          code.call(network, node, machine) if code
        end        
      end
    end
  end
  
  #---
  
  def self.load_network(directory)
    # Load network if it exists
    CORL.network(
      :vagrant, 
      CORL.config(:vagrant_network, { :directory => directory, :name => directory })
    )
  end
  
  #---
  
  def self.configure_vagrant(network, vagrant)
    success = true
    Util::Data.hash(network.settings(:vagrant_config)).each do |name, data|
      if vagrant.respond_to?("#{name}=")
        data = Util::Data.value(data)
        #dbg(name, 'vagrant property')
        #dbg(data, 'vagrant property data')
        vagrant.send("#{name}=", data)
      else
        params = parse_params(data)
        #dbg(name, 'vagrant method')
        #dbg(params, 'vagrant method params')
        vagrant.send(name, params)  
      end
    end
    success
  end
  
  #---
  
  def self.configure_ssh(node, machine)
    success = true
    
    #dbg(node.user, 'ssh user')
    machine.ssh.username = node.user
    
    #dbg(node.ssh_port, 'ssh port')
    machine.ssh.guest_port = node.ssh_port
        
    if node.cache_setting(:use_private_key, false)
      #dbg(node.private_key, 'ssh private key')
      machine.ssh.private_key_path = node.private_key
    end
    
    Util::Data.hash(node.ssh).each do |name, data|
      if machine.ssh.respond_to?("#{name}=")
        data = Util::Data.value(data)
        #dbg(name, 'ssh property')
        #dbg(data, 'ssh property data')
        machine.ssh.send("#{name}=", data)
      else
        params = parse_params(data)
        #dbg(name, 'ssh method')
        #dbg(params, 'ssh method params')
        machine.ssh.send(name, params)  
      end
    end
    success
  end
  
  #---
  
  def self.configure_vm(node, machine)
    vm_config = Util::Data.hash(node.vm)
    success   = true
    
    #dbg(node.hostname, 'VM hostname')
    machine.vm.hostname = node.hostname
    
    box     = node.cache_setting(:box)
    box_url = node.cache_setting(:box_url)
    
    if box && box_url
      #dbg(box, 'VM box')
      machine.vm.box     = box
      #dbg(box_url, 'VM box url')
      machine.vm.box_url = box_url  
    else
      #dbg(node.image, 'VM box')
      machine.vm.box = node.image
    end
    
    unless vm_config.has_key?(:public_network)
      if node.public_ip
        #dbg(node.public_ip, 'private ip address')
        machine.vm.network :private_network, :ip => node.public_ip
      else
        #dbg('dhcp private ip address')
        machine.vm.network :private_network, :type => "dhcp"
      end
    end
       
    vm_config.each do |name, data|
      case name.to_sym
      # Network interfaces
      when :forwarded_ports
        data.each do |forward_name, info|
          forward_config = CORL::Config.new({ :auto_correct => true }).import(info)
          
          forward_config.keys do |key|
            forward_config[key] = Util::Data.value(forward_config[key])
          end
          #dbg(forward_config.export, 'vm forwarded port config')          
          machine.vm.network :forwarded_port, forward_config.export
        end
      when :usable_port_range
        low, high = data.to_s.split(/\s*--?\s*/)
        #dbg("#{low} <--> #{high}", 'vm usable port range')     
        machine.vm.usable_port_range = Range.new(low, high)
        
      when :public_network
        #dbg('public network')
        machine.vm.network :public_network
        
      # Provider specific settings
      when :providers
        data.each do |provider, info|
          #dbg(provider, 'vm provider')
          machine.vm.provider provider.to_sym do |interface|
            info.each do |property, item|
              #dbg(property, 'vm property')
              #dbg(item, 'vm property item')
              if interface.respond_to?("#{property}=")
                interface.send("#{property}=", item)
              else
                params = parse_params(item)
                #dbg(params, 'vm method params')
                interface.send(property, params)
              end
            end
          end
        end
      # All other basic VM settings...
      else
        if machine.vm.respond_to?("#{name}=")
          #dbg(name, 'other property')
          #dbg(data, 'other property data')
          machine.vm.send("#{name}=", data)
        else
          params = parse_params(data)
          #dbg(name, 'other method')
          #dbg(params, 'other method params')
          machine.vm.send(name, params)
        end
      end  
    end
    success
  end
  
  #---
  
  def self.configure_shares(node, machine)
    success = true
    
    Util::Data.hash(node.shares).each do |name, options|
      config     = CORL::Config.ensure(options)      
      local_dir  = config.delete(:local, '')
      remote_dir = config.delete(:remote, '')
      
      config.init(:create, true)
      
      unless local_dir.empty? || remote_dir.empty?
        share_options = {}
      
        config.keys.each do |key|
          share_options[key] = Util::Data.value(config[key])
        end
        
        #dbg(local_dir, 'vm share local')
        #dbg(remote_dir, 'vm share remote')
        #dbg(share_options, 'vm share options')     
        machine.vm.synced_folder local_dir, remote_dir, share_options
      end
    end    
    success
  end
  
  #---
  
  def self.configure_provisioner(network, node, machine)
    success = true
    
    # CORL provisioning
    machine.vm.provision :corl do |provisioner|
      provisioner.network_path = CORL::Config.fact(:corl_network)
      provisioner.network      = network
      provisioner.node         = node    
    end
    success  
  end
  
  #---
  
  def self.parse_params(data)    
    params = data
    if data.is_a?(Hash)
      params = []
      data.each do |key, item|
        unless Util::Data.undef?(item)
          params << ( key.match(/^\:/) ? key.gsub(/^\:/, '').to_sym : key.to_s )
          unless Util::Data.empty?(item)
            value = item
            value = ((item.is_a?(String) && item.match(/^\:/)) ? item.gsub(/^\:/, '').to_sym : item)
            params << Util::Data.value(value)
          end
        end
      end
    end
    params
  end
end
end
end
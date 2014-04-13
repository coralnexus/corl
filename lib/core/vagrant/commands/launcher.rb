
module VagrantPlugins
module CORL
module Command
class Launcher < ::Vagrant.plugin("2", :command)
  
  include ::CORL::Parallel # Mainly for auto locking of resources
  
  #-----------------------------------------------------------------------------
  
  def self.synopsis
    "execute CORL actions within the defined network"
  end
 
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def env
    @env
  end
  
  #-----------------------------------------------------------------------------
  # Execution

  def execute
    # Set the base command so we can access in any actions executed
    ::CORL::Vagrant.command = ::CORL.handle(self)   
    ::CORL.executable(@argv - [ "--" ], "vagrant corl")
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def vm_machine(name, provider = nil, refresh = false)
    machine = nil
    
    # Mostly derived from Vagrant base command with_target_vms() method 
    provider = provider.to_sym if provider

    env.active_machines.each do |active_name, active_provider|
      if name == active_name
        if provider && provider != active_provider
          raise ::Vagrant::Errors::ActiveMachineWithDifferentProvider,
            :name               => active_name.to_s,
            :active_provider    => active_provider.to_s,
            :requested_provider => provider.to_s
        else
          @logger.info("Active machine found with name #{active_name}. " +
                       "Using provider: #{active_provider}")
          provider = active_provider
          break
        end
      end
    end

    provider ||= env.default_provider
    
    machine = env.machine(name, provider, refresh)
    machine.ui.opts[:color] = :default # TODO: Something better??
    
    machine
  end
end
end
end
end

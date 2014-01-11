
module Coral
module Plugin
class Machine < Base

  #-----------------------------------------------------------------------------
  # Machine plugin interface
 
      
  #-----------------------------------------------------------------------------
  # Checks
  
  def created?
    return false
  end
  
  #---
  
  def running?
    return ( created? && false )
  end
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def hostname(default = '')
    return get(:hostname, default)
  end
  
  #---
  
  def public_ip(default = '')
    return get(:public_ip, default)
  end
  
  #---
  
  def private_ip(default = nil)
    return get(:private_ip, default)
  end
            
  #-----------------------------------------------------------------------------
  # Management 

  def create(options = {})
    unless created?
      
    end
    return true
  end
  
  #---
  
  def update(options = {})
    if created?
      
    end
    return true
  end
  
  #---
  
  def start(options = {})
    unless running?
      
    end
    return true
  end
  
  #---
  
  def stop(options = {})
    if running?
      
    end
    return true
  end
  
  #---
  
  def reload(options = {})
    if created?
      
    end
    return true
  end

  #---

  def destroy(options = {})   
    if created?
        
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  
  def provision(options = {})
    if running?
      config = Config.ensure(options)
      
      # TODO: Abstract this out so it does not depend on Puppet functionality.
      
      puppet  = config.delete(:puppet, :puppet) # puppet (community) or puppetlabs (enterprise)     
      command = Coral.command({
        :command    => :puppet,
        :flags      => config.delete(:puppet_flags, ''),
        :subcommand => {
          :command => config.delete(:puppet_op, :apply),
          :flags   => config.delete(:puppet_op_flags, ''),
          :data    => config.delete(:puppet_op_data, {}).merge({
            'modulepath=' => array(config.delete(:puppet_modules, "/etc/#{puppet}/modules")).join(':')
          }),
          :args => config.delete(:puppet_manifest, "/etc/#{puppet}/manifests/site.pp")
        }
      }, config.get(:provider, :puppet))
      
      config[:commands] = command.to_s
      return exec(config)
    end
    return true
  end
  
  #---
  
  def create_image(options = {})
    if created?
      
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  
  def exec(options = {})
    if running?
      config = Config.ensure(options)
      if commands = config.delete(:commands)
        commands.each do |command|
          Util::Shell.exec!(command, config) do |line|
            yield(line) if block_given?
          end
        end
      end  
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  # Utilities

end
end
end
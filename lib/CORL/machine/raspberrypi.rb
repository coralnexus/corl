
module CORL
module Machine
class Raspberrypi < Nucleon.plugin_class(:CORL, :machine)

  include Mixin::Machine::SSH

  #-----------------------------------------------------------------------------
  # Machine plugin interface

  def normalize(reload)
    require 'net/ping'

    super
    myself.plugin_name = node.plugin_name if node
  end

  #-----------------------------------------------------------------------------
  # Checks

  def created?
    true
  end

  #---

  def running?
    Net::Ping::TCP.new(public_ip, node.ssh_port).ping?
  end

  #-----------------------------------------------------------------------------
  # Property accessors / modifiers

  def public_ip
    node[:public_ip]
  end

  #---

  def state
    running? ? :running : :not_running
  end

  #---

  def machine_type
    'raspberrypi'
  end

  #---

  def image
    nil
  end

  #-----------------------------------------------------------------------------
  # Management

  def load
    super do
      true
    end
  end

  #---

  def create(options = {})
    super do
      logger.warn("Damn!  We can't create new instances of Raspberry Pi machines")
      true
    end
  end

  #---

  def download(remote_path, local_path, options = {}, &code)
    super do |config, success|
      ssh_download(remote_path, local_path, config, &code)
    end
  end

  #---

  def upload(local_path, remote_path, options = {}, &code)
    super do |config, success|
      ssh_upload(local_path, remote_path, config, &code)
    end
  end

  #---

  def exec(commands, options = {}, &code)
    super do |config|
      ssh_exec(commands, config, &code)
    end
  end

  #---

  def terminal(user, options = {})
    super do |config|
      ssh_terminal(user, config)
    end
  end

  #---

  def reload(options = {})
    super do
      node.command('reboot', { :as_admin => true })
    end
  end

  #---

  def create_image(options = {})
    super do
      logger.warn("Creating images of Raspberry Pi machines not supported yet")
      true
    end
  end

  #---

  def stop(options = {})
    super do
      logger.warn("Stopping a Raspberry Pi machine is not supported right now")
      true
    end
  end

  #---

  def start(options = {})
    super do
      logger.warn("Starting a Raspberry Pi machine is not supported right now")
      true
    end
  end

  #---

  def destroy(options = {})
    super do
      logger.warn("If you want to destroy your Raspberry Pi machine, grab a hammer")
      true
    end
  end

  #-----------------------------------------------------------------------------
  # Utilities

end
end
end

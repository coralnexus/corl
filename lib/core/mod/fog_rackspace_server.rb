module Fog
module Compute
class RackspaceV2
class Server

  def setup(credentials = {})
    requires :ssh_ip_address, :identity, :public_key, :username

    commands = [
      %{mkdir .ssh},
      %{echo "#{public_key}" >> ~/.ssh/authorized_keys},
      password_lock,
      %{echo "#{Fog::JSON.encode(attributes)}" >> ~/attributes.json},
      %{echo "#{Fog::JSON.encode(metadata)}" >> ~/metadata.json}
    ]
    commands.compact

    @password = nil if password_lock

    Fog::SSH.new(ssh_ip_address, username, credentials).run(commands)

  rescue Errno::ECONNREFUSED, Net::SSH::Disconnect
    sleep(1)
    retry
  end
end
end
end
end

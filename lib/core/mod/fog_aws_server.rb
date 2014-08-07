module Fog
module Compute
class AWS
class Server
  
  def setup(credentials = {})
    requires :ssh_ip_address, :username
    
    commands = [
      %{mkdir .ssh},
      %{passwd -l #{username}},
      %{echo "#{Fog::JSON.encode(Fog::JSON.sanitize(attributes))}" >> ~/attributes.json}
    ]
    if public_key
      commands << %{echo "#{public_key}" >> ~/.ssh/authorized_keys}
    end

    tries      = 5
    sleep_secs = 5
    
    begin      
      Nucleon::Util::SSH.session(ssh_ip_address, username, ssh_port, private_key_path, true)
      results = Nucleon::Util::SSH.exec(ssh_ip_address, username, commands)
            
    rescue Net::SSH::HostKeyMismatch => error
      error.remember_host!
      sleep 0.2
      retry
      
    rescue Errno::ECONNREFUSED, Net::SSH::ConnectionTimeout, Net::SSH::Disconnect => error   
      if tries > 1
        sleep(sleep_secs)
        
        tries -= 1
        retry
      end
    end
  end
end
end
end
end

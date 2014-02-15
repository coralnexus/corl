
Facter.add(:coral_network) do
  confine :kernel => :linux
    
  setcode do
    require 'coral_core'
    
    network_path = '/var/coral'
    
    Coral.exec(:network_location) do |op, results|
      if op == :process
        network_path = results unless results.nil? || ! File.directory?(results) 
      end
    end    
    network_path
  end
end

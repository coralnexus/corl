
Facter.add(:corl_network) do
  confine :kernel => :linux
    
  setcode do
    require 'corl'
    
    network_path = '/var/corl'
    
    CORL.exec(:network_location) do |op, results|
      if op == :process
        network_path = results unless results.nil? || ! File.directory?(results) 
      end
    end    
    network_path
  end
end

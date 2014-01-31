
Facter.add(:coral_network) do
  confine :kernel => :linux
    
  setcode do
    begin 
      coral_network = '/var/coral'
      
      if Dir.directory?(coral_network)
        success = true
      end
      
    rescue Exception # Prevent abortions.
    end
  
    success ? coral_network : nil
  end
end

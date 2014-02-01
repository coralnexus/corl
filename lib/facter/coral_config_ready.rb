
Facter.add(:coral_config_ready) do  
  setcode do
    begin 
      require 'coral_core'      
      configured = Coral::Config.config_initialized?
      
    rescue Exception # Prevent abortions.
    end
  
    configured ? true : nil
  end
end

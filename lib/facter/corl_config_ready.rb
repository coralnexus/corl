
Facter.add(:corl_config_ready) do  
  setcode do
    begin 
      require 'corl'      
      configured = CORL::Config.config_initialized?
      
    rescue Exception # Prevent abortions.
    end
  
    configured ? true : nil
  end
end

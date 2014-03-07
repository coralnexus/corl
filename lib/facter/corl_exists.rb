
Facter.add(:corl_exists) do
  confine :kernel => :linux
  
  setcode do
    corl_exists = nil 
    begin
      Facter::Util::Resolution::exec('gem list corl -i 2> /dev/null')
      corl_exists = true if $?.exitstatus == 0
      
    rescue Exception # Prevent abortions.
    end    
    corl_exists
  end
end
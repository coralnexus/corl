
Facter.add(:coral_exists) do
  confine :kernel => :linux
  
  setcode do
    begin
      Facter::Util::Resolution::exec('gem list coral_core -i 2> /dev/null')
      coral_exists = true if $?.exitstatus == 0
      
    rescue Exception # Prevent abortions.
    end
    
    coral_exists ? true : nil
  end
end
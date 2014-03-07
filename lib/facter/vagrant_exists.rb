
Facter.add(:vagrant_exists) do
  confine :kernel => :linux
  
  setcode do
    vagrant_exists = nil    
    begin
      Facter::Util::Resolution::exec('id vagrant 2> /dev/null')
      vagrant_exists = true if $?.exitstatus == 0
      
    rescue Exception # Prevent abortions.
    end    
    vagrant_exists
  end
end

Facter.add(:corl_build) do
  confine :kernel => :linux # TODO: Extend this to work with more systems
    
  setcode do
    File.join(Facter.value('corl_network'), 'build')
  end
end


Facter.add(:raspberry_pi) do
  confine :kernel => :linux

  setcode do
    raspberry_pi = nil
    begin
      raspberry_pi = true if File.exist?('/usr/lib/raspberrypi')

    rescue # Prevent abortions.
    end
    raspberry_pi
  end
end
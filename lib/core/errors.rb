
module CORL
module Errors
  class SSHUnavailable < NucleonError
    error_key(:ssh_unavailable)
  end

  class SSHIsPuttyLink < NucleonError
    error_key(:ssh_is_putty_link)
  end   
end
end
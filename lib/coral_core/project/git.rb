
module Coral
module Project
class Git < Base
  #-----------------------------------------------------------------------------
  # Project information
   
  def normalize
    super
    unless get(:revision, false)
      set(:revision, 'master')
    end
  end
end
end
end

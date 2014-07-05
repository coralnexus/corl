
nucleon_require(File.dirname(__FILE__), :group)

#---

module Nucleon
module Action
module Node
class Groups < Group
 
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:groups, 671)
  end
  
  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super(true)
  end
  
  #---
  
  def arguments
    []
  end
end
end
end
end

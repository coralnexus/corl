
nucleon_require(File.dirname(__FILE__), :fact)

#---

module Nucleon
module Action
module Node
class Facts < Fact
 
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:facts, 571)
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

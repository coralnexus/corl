
module Nucleon
module Action
class Plugins < Plugin::List
   
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    describe_base(nil, :plugins, 1)
  end
end
end
end

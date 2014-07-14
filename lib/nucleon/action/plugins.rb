
module Nucleon
module Action
class Plugins < Plugin::List
   
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    describe_base(nil, :plugins, 1, nil, nil, :plugin_list)
  end
  
  #-----------------------------------------------------------------------------
  # Output
  
  def render_provider
    :plugin_list
  end
end
end
end

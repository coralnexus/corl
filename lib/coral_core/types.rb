
module Coral
module Plugin
  define_type :extension     => nil,         # Core
              :configuration => :file,       # Core
              :action        => :update,     # Core
              :project       => :git,        # Core
              :network       => :default,    # Cluster
              :node          => :local,      # Cluster
              :machine       => :physical,   # Cluster
              :provisioner   => :puppetnode, # Cluster
              :command       => :shell,      # Cluster
              :event         => :regex,      # Utility
              :template      => :json,       # Utility
              :translator    => :json        # Utility
end 
end

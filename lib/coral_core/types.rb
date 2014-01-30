
module Coral
module Plugin
  define_type :extension     => nil,        # Core
              :configuration => :file,      # Core
              :action        => :update,    # Core
              :project       => :git,       # Core
              :network       => :default,   # Cluster
              :node          => :rackspace, # Cluster
              :machine       => :fog,       # Cluster
              :provisioner   => :puppet,    # Cluster
              :command       => :shell,     # Cluster
              :event         => :regex,     # Utility
              :template      => :json,      # Utility
              :translator    => :json       # Utility
end 
end

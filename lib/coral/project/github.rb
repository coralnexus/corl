
coral_require(File.dirname(__FILE__), :git)

#---

module Coral
module Project
class Github < Git
 
  #-----------------------------------------------------------------------------
  # Project plugin interface
 
  def normalize 
    set(:url, self.class.expand_url(get(:url), get(:ssh, false))) if get(:url)
    super
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.expand_url(path, editable = false)
    if editable
      protocol  = 'git@'
      separator = ':'
    else
      protocol  = 'https://'
      separator = '/'
    end
    return "#{protocol}github.com#{separator}" + path + '.git'  
  end
end
end
end

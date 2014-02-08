
coral_require(File.dirname(__FILE__), :git)

#---

module Coral
module Project
class Github < Git
 
  #-----------------------------------------------------------------------------
  # Project plugin interface
 
  def normalize
    require 'octokit'
    
    if reference = delete(:reference, nil)
      self.name = reference
    else
      if url = get(:url, nil)
        self.name = url
        set(:url, self.class.expand_url(url, get(:ssh, false)))
      end  
    end    
    super
  end
  
  #-----------------------------------------------------------------------------
  # Project operations
  
  def init_auth
    super do
      key_id  = ENV['USER'] + '@' + lookup(:ipaddress)
      ssh_key = public_key_str
      
      if private_key && ssh_key
        begin
          client = Octokit::Client.new :netrc => true
          client.login        
          
          result = client.add_deploy_key(self.name, key_id, ssh_key)
        
        rescue Exception => error
          logger.error(error.inspect)
          logger.error(error.message)
          logger.error(Util::Data.to_yaml(error.backtrace))

          ui.error(error.message, { :prefix => false }) if error.message
        end
      end
    end  
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

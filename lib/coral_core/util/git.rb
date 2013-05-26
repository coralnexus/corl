
module Git

  #-----------------------------------------------------------------------------
  # Utilities

  def self.url(host, repo, options = {})
    options[:user] = ( options[:user] ? options[:user] : 'git' )
    options[:auth] = ( options[:auth] ? options[:auth] : true )
    
    return options[:user] + ( options[:auth] ? '@' : '://' ) + host + ( options[:auth] ? ':' : '/' ) + repo
  end
end

#---

module Grit
  class Repo
    
    #---------------------------------------------------------------------------
    # Remotes
    
    def remote_set_url(name, url, opts = {})
      self.git.remote(opts, 'set-url', name, url)
    end
    
    #---
    
    def remote_rm(name)
      if self.list_remotes.include?(name)
        self.git.remote({}, 'rm', name)
      end
    end
  end
end
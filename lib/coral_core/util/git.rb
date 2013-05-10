
module Git

  #-----------------------------------------------------------------------------
  # Utilities

  def self.url(host, repo, options = {})
    options[:user] = ( options[:user] ? options[:user] : 'git' )
    options[:auth] = ( options[:auth] ? options[:auth] : true )
    
    return options[:user] + ( options[:auth] ? '@' : '://' ) + host + ( options[:auth] ? ':' : '/' ) + repo
  end
end
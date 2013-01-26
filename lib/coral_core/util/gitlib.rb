
require 'git'

module Coral
module Util
class GitLib < Core

  #-----------------------------------------------------------------------------
  # Utilities

  def self.open(root_dir, submodule = '')
    repo_dir = root_dir
    
    unless submodule.empty?
      repo_dir = File.join(root_dir, submodule)
    end
        
    if File.directory?(File.join(repo_dir, '.git'))
      git = Git.open(repo_dir, { :log => logger })
      
    elsif ! submodule.empty?
      git = Git.open(repo_dir, {
        :working_directory => repo_dir,
        :repository        => File.join(root_dir, '.git', 'modules', submodule),
        :index             => File.join(root_dir, '.git', 'modules', submodule, 'index'),
        :log               => logger,
      })
    end
    return git
  end
    
  #---
    
  def self.url(host, repo, options = {})
    options[:user] = ( options[:user] ? options[:user] : 'git' )
    options[:auth] = ( options[:auth] ? options[:auth] : true )
    
    return options[:user] + ( options[:auth] ? '@' : '://' ) + host + ( options[:auth] ? ':' : '/' ) + repo
  end
end
end
end